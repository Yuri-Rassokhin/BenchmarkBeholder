require 'json'
require 'net/ssh'
require 'method_source'
require 'shellwords'
require 'ripper'
require 'set'
require 'singleton'

module Global
  class Hub
    include Singleton

    def initialize
      @method_hosts = {}        # method_name => текущий хост
      @original_methods = {}    # method_name => { method:, context:, body: }
      @@landed_methods = Set.new
    end

    def run(context, method, host, *args)
      puts "DEBUG run: method=#{method.inspect}, host=#{host}, args=#{args.inspect}"
      execute_remotely(method, context, host, *args)
    end

    def land(context, target = nil, method_name, host)
      callable = method_name
      puts "DEBUG land(before): callable=#{callable.inspect}, method_name=#{method_name}"

      klass = target.nil? ? Object : target
      is_original_method = callable.is_a?(Method)
      original_method_obj = callable if is_original_method

      # ✅ Генерация уникального имени
      unless method_name.is_a?(Symbol) || method_name.is_a?(String)
        if is_original_method
          method_name = "__global_#{original_method_obj.receiver.class.name.downcase}_#{original_method_obj.name}".gsub(/\?/, '').to_sym
        else
          method_name = :"__global_callable_#{object_id}"
        end
      end

      puts "DEBUG land(after): method_name=#{method_name}"
      @method_hosts[method_name] = host

      # ✅ Создание временного метода для Method без исходника
      if is_original_method && !@original_methods.key?(method_name)
        if !klass.method_defined?(method_name)
          body = <<~RUBY
            def #{method_name}(*args)
              #{original_method_obj.receiver}.#{original_method_obj.name}(*args)
            end
          RUBY
          klass.class_eval(body)
          puts "DEBUG: temporary method #{method_name} created in #{klass}"

          @original_methods[method_name] = {
            method: klass.instance_method(method_name),
            context: context,
            body: body
          }
        else
          @original_methods[method_name] = {
            method: klass.instance_method(method_name),
            context: context,
            body: ""
          }
        end
      end

      # ✅ Обычные методы / Proc
      unless @original_methods.key?(method_name)
        original_method =
          case callable
          when Symbol, String
            klass.instance_method(method_name.to_sym)
          when Proc
            if callable.respond_to?(:source)
              callable
            else
              klass.define_method(method_name, &callable)
              klass.instance_method(method_name)
            end
          else
            raise TypeError, "#{callable.inspect} is not a symbol, string, Method, or Proc" unless is_original_method
          end

        @original_methods[method_name] ||= {
          method: original_method,
          context: context,
          body: ""
        }
      end

      # ✅ Сохраняем зависимости (только для символов/строк)
      if callable.is_a?(Symbol) || callable.is_a?(String)
        full_dependency_chain(method_name.to_sym).each do |dependency|
          unless @original_methods.key?(dependency)
            method_obj = Object.instance_method(dependency)
            @original_methods[dependency] = { method: method_obj, context: context, body: "" }
          end
        end
      end

      hub_instance = self

      klass.define_method(method_name) do |*args, &block|
        puts "DEBUG: local method #{method_name} invoked with args=#{args.inspect}, sending to remote..."
        current_host = hub_instance.instance_variable_get(:@method_hosts)[method_name]
        remote_result = hub_instance.run(context, method_name, current_host, *args, &block)

        updated_variables = remote_result["variables"]
        updated_variables.each do |key, value|
          context.eval("#{key} = #{value.inspect}") if key.start_with?("@")
        end

        puts remote_result["output"] if remote_result["output"]
        remote_result["result"]
      end

      puts "DEBUG land: method #{method_name} defined, ready for run!"
      method_name
    end

    def run!(context, method_name, host, *args, target: nil)
      final_name = land(context, target, method_name, host)
      puts "DEBUG run!: invoking #{final_name} via Object.send"
      Object.send(final_name, *args)
    rescue => e
      puts "DEBUG run!: failed to invoke #{method_name} -> #{e.class}: #{e.message}"
      raise
    end

    private

    def method_dependencies(method)
      return [] unless method.respond_to?(:source)
      begin
        source = method.source
      rescue MethodSource::SourceNotFoundError
        puts "DEBUG method_dependencies: dynamic method #{method}, skipping dependencies"
        return []
      end

      dependencies = []
      sexp = Ripper.sexp(source)
      traverse_sexp(sexp) do |node|
        if node.is_a?(Array) && node[0] == :vcall
          dependencies << node[1][1].to_sym if node[1].is_a?(Array) && node[1][0] == :@ident
        elsif node.is_a?(Array) && node[0] == :call
          dependencies << node[2][1].to_sym if node[2].is_a?(Array) && node[2][0] == :@ident
        end
      end
      dependencies.uniq
    end

    def traverse_sexp(sexp, &block)
      return unless sexp.is_a?(Array)
      yield(sexp)
      sexp.each { |node| traverse_sexp(node, &block) }
    end

    def full_dependency_chain(method_name, seen_methods = Set.new)
      return [] if seen_methods.include?(method_name)
      seen_methods.add(method_name)

      unless @original_methods.key?(method_name)
        begin
          method_obj = Object.instance_method(method_name)
          context = binding
          @original_methods[method_name] = { method: method_obj, context: context, body: "" }
        rescue NameError
          return []
        end
      end

      method_obj = @original_methods[method_name][:method]
      dependencies = method_dependencies(method_obj)
      full_chain = dependencies.flat_map { |dependency| full_dependency_chain(dependency, seen_methods) }
      [method_name] + full_chain.uniq
    end

    def output_dependency_chain(method_name)
      result = ""
      chain = full_dependency_chain(method_name)
      chain.each do |dependency|
        begin
          method_obj = @original_methods[dependency][:method]
          if method_obj.respond_to?(:source)
            begin
              result << method_obj.source + "\n"
            rescue MethodSource::SourceNotFoundError
              puts "DEBUG output_dependency_chain: no source for #{dependency}, skipping"
            end
          end
        rescue => e
          result << "# Error processing dependency #{dependency}: #{e.message}\n"
        end
      end
      result
    end

    def get_context_variables(context)
      instance_vars = context.eval('instance_variables').map { |var| [var, context.eval(var.to_s)] }
      class_vars = if context.eval('self').is_a?(Class) || context.eval('self').is_a?(Module)
                     context.eval('self.class_variables').map { |var| [var, context.eval("self.class_variable_get(:#{var})")] }
                   else
                     []
                   end
      constants = if context.eval('self').is_a?(Class) || context.eval('self').is_a?(Module)
                    context.eval('self.constants').map { |const| [const, context.eval("self.const_get(:#{const})")] }
                  else
                    []
                  end
      (instance_vars + class_vars + constants).to_h
    end

    def serialize_method(method_name, caller_context)
      method_obj = @original_methods[method_name][:method]
      context = @original_methods[method_name][:context] || caller_context

      method_body = ""
      if method_obj.respond_to?(:source)
        begin
          method_body = method_obj.source
        rescue MethodSource::SourceNotFoundError
          puts "DEBUG serialize_method: dynamic method #{method_name}, using stored body"
          method_body = @original_methods[method_name][:body] || ""
        end
      else
        method_body = @original_methods[method_name][:body] || ""
      end

      {
        method_name: method_name,
        method_body: method_body,
        dependencies: get_context_variables(context)
      }.to_json
    end

    def add_parameter_to_method(method_body, new_param)
      method_body.sub(/def\s+(\w+)(\(([^)]*)\))?/) do
        method_name = Regexp.last_match(1)
        params = Regexp.last_match(3) || ""
        updated_params = params.empty? ? new_param : "#{params}, #{new_param}"
        "def #{method_name}(#{updated_params})"
      end
    end

    def execute_remotely(method_name, context, host, *args)
      puts "DEBUG execute_remotely: #{method_name}, args=#{args.inspect}"
      serialized_data = serialize_method(method_name, context)
      data = JSON.parse(serialized_data)

      deps = ""
      data["dependencies"].each do |key, value|
        deps << "#{key} = #{value.inspect}\n" if key.start_with?("@", "@@", "$")
      end

      method_definitions = data["method_body"].to_s + "\n" + output_dependency_chain(method_name)
      serialized_args = args.map(&:inspect).join(", ")

      remote_script = <<~RUBY
        require 'json'
        require 'stringio'
        output_stream = StringIO.new
        original_stdout = $stdout
        original_stderr = $stderr
        $stdout = output_stream
        $stderr = $stderr

        begin
          #{deps}
          #{method_definitions}
          result = #{method_name}(#{serialized_args})
          updated_variables = {
            #{data["dependencies"].keys.map { |key| "\"#{key}\": #{key}" }.join(", ")}
          }
        ensure
          $stdout = original_stdout
          $stderr = $stderr
        end

        output = {
          variables: updated_variables,
          output: output_stream.string.strip,
          result: result
        }
        puts output.to_json
      RUBY

      output = ""
      File.write("/tmp/code_dump.txt", remote_script) # DEBUG
      Net::SSH.start(host) do |ssh|
        output = ssh.exec!("ruby -e #{Shellwords.escape(remote_script)}")
      end
      begin
        File.write("/tmp/result_dump.txt", output) # DEBUG
        JSON.parse(output.strip)
      rescue => e
        puts "global execution error: #{e.message}"
      end
    end
  end

  # ✅ Делегация
  def self.run!(context, method, host, *args)
    Hub.instance.run(context, method, host, *args)
  end

  def self.land(context, target = nil, method_name, host)
    Hub.instance.land(context, target, method_name, host)
  end

  def self.run(context, host, method_name, *args, target: nil)
    Hub.instance.run!(context, method_name, host, *args, target: target)
  end
end

