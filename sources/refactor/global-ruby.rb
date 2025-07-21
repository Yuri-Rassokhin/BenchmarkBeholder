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
      @original_methods = {}    # method_name => { method: UnboundMethod, context: Binding }
      @@landed_methods = Set.new
    end

    def run(context, method, host, *args)
      execute_remotely(method, context, host, *args)
    end

    def land(context, target = nil, method_name, host)
      @method_hosts[method_name] = host

      klass = target.nil? ? Object : target

      # ✅ Сохраняем оригинал ТОЛЬКО один раз
      unless @original_methods.key?(method_name)
        original_method = klass.instance_method(method_name)
        @original_methods[method_name] = { method: original_method, context: context }
      end

      # ✅ Также сохраняем зависимости один раз
      full_dependency_chain(method_name).each do |dependency|
        unless @original_methods.key?(dependency)
          method_obj = Object.instance_method(dependency)
          @original_methods[dependency] = { method: method_obj, context: context }
        end
      end

      hub_instance = self

      # ✅ Каждый land переопределяет метод с актуальным хостом
      klass.define_method(method_name) do |*args, &block|
        current_host = hub_instance.instance_variable_get(:@method_hosts)[method_name]
        remote_result = hub_instance.run(context, method_name, current_host, *args, &block)

        updated_variables = remote_result["variables"]
        updated_variables.each do |key, value|
          context.eval("#{key} = #{value.inspect}") if key.start_with?("@")
        end

        puts remote_result["output"] if remote_result["output"]
        remote_result["result"]
      end
    end

  def run!(context, method_name, host, *args, target: nil)
    land(context, target, method_name, host)
    context.eval("#{method_name}(#{args.map(&:inspect).join(', ')})")
  end

    private

    def method_dependencies(method)
      source = method.source
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
          @original_methods[method_name] = { method: method_obj, context: context }
        rescue NameError
          return []
        end
      end

      method_obj = @original_methods[method_name][:method]
      dependencies = method_dependencies(method_obj)

      full_chain = dependencies.flat_map do |dependency|
        full_dependency_chain(dependency, seen_methods)
      end

      [method_name] + full_chain.uniq
    end

    def output_dependency_chain(method_name)
      result = ""
      chain = full_dependency_chain(method_name)
      chain.each do |dependency|
        begin
          method_obj = @original_methods[dependency][:method]
          result << method_obj.source + "\n"
        rescue => e
          result << "# Error processing dependency #{dependency}: #{e.message}\n"
        end
      end
      result
    end

    def get_context_variables(context)
      instance_vars = context.eval('instance_variables').map do |var|
        [var, context.eval(var.to_s)]
      end

      class_vars = if context.eval('self').is_a?(Class) || context.eval('self').is_a?(Module)
                     context.eval('self.class_variables').map do |var|
                       [var, context.eval("self.class_variable_get(:#{var})")]
                     end
                   else
                     []
                   end

      constants = if context.eval('self').is_a?(Class) || context.eval('self').is_a?(Module)
                    context.eval('self.constants').map do |const|
                      [const, context.eval("self.const_get(:#{const})")]
                    end
                  else
                    []
                  end

      (instance_vars + class_vars + constants).to_h
    end

    def serialize_method(method_name, caller_context)
      method_obj = @original_methods[method_name][:method]
      context = @original_methods[method_name][:context] || caller_context
      {
        method_name: method_name,
        method_body: method_obj.source,
        dependencies: get_context_variables(context)
      }.to_json
    end

    def add_parameter_to_method(method_body, new_param)
      method_body.sub(/def\s+(\w+)(\(([^)]*)\))?/) do |match|
        method_name = Regexp.last_match(1)
        params = Regexp.last_match(3) || ""
        updated_params = params.empty? ? new_param : "#{params}, #{new_param}"
        "def #{method_name}(#{updated_params})"
      end
    end

    def execute_remotely(method_name, context, host, *args)
      serialized_data = serialize_method(method_name, context)
      data = JSON.parse(serialized_data)

      deps = ""
      data["dependencies"].each do |key, value|
        deps << "#{key} = #{value.inspect}\n" if key.start_with?("@", "@@", "$")
      end

      method_definitions = output_dependency_chain(method_name)
      serialized_args = args.map(&:inspect).join(", ")

      remote_script = <<~RUBY
        require 'json'
        require 'stringio'
        output_stream = StringIO.new
        original_stdout = $stdout
        original_stderr = $stderr
        $stdout = output_stream
        $stderr = output_stream

        begin
          #{deps}
          #{method_definitions}
          result = #{method_name}(#{serialized_args})
          updated_variables = {
            #{data["dependencies"].keys.map { |key| "\"#{key}\": #{key}" }.join(", ")}
          }
        ensure
          $stdout = original_stdout
          $stderr = original_stderr
        end

        output = {
          variables: updated_variables,
          output: output_stream.string.strip,
          result: result
        }
        puts output.to_json
      RUBY

      output = ""
      Net::SSH.start(host) do |ssh|
        output = ssh.exec!("ruby -e #{Shellwords.escape(remote_script)}")
      end
      JSON.parse(output.strip)
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

