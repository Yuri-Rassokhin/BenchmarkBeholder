require 'logger'
require 'time'

# Logger setup
$log = Logger.new(STDOUT)

$log.formatter = proc do |severity, datetime, progname, msg|
  "[#{severity}] #{msg}\n"
end

# Module for logging method invocations
module MethodLogger
  def self.prepended(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def method_added(method_name)
      return if @logging_in_progress

      @logging_in_progress = true
      original_method = instance_method(method_name)

      define_method(method_name) do |*args, &block|
        start_time = Time.now
        $log.info("Calling #{self.class}.#{method_name}(#{args.inspect})")

        result = original_method.bind(self).call(*args, &block)

        end_time = Time.now
        time = (end_time - start_time).round(2)
        header = time > 0.5 ? "HOT " : ""
        $log.info("#{header}#{time} sec #{self.class}.#{method_name}(#{args.inspect})")

        result
      end

      @logging_in_progress = false
    end

    def singleton_method_added(method_name)
      return if @logging_in_progress

      @logging_in_progress = true
      original_method = method(method_name)

      define_singleton_method(method_name) do |*args, &block|
        start_time = Time.now
        $log.info("Calling #{self.class}.#{method_name}(#{args.inspect})")

        result = original_method.call(*args, &block)

        end_time = Time.now
        time = (end_time - start_time).round(2)
        header = time > 0.5 ? "HOT " : ""
        $log.info("#{header}#{time} sec #{self}.#{method_name}(#{args.inspect})")

        result
      end

      @logging_in_progress = false
    end
  end
end

# Prepend the logger to Object class
class Object
  prepend MethodLogger
end

