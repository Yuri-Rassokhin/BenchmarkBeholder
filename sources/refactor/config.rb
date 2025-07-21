require 'json'
require 'dry-validation'

class Config

def initialize(logger, config_path)
  @logger = logger
  @data = load_json(config_path)
  @schema = "./hooks/#{name}/parameters.rb"
  result = check
  if !result.success?
      result.errors.each do |error|
      path = error.path.reject { |p| p.is_a?(Integer) }.join('.')
      value = error.path.reduce(@data) do |acc, key|
        acc.is_a?(Hash) ? acc[key] : acc[key] rescue nil
      end
      @logger.msg "Incorrect value '#{value}' in #{path}, #{error.text}"
    end
  end
end

def name
  get(:workload, :name)
end

def actor
  get(:workload, :actor)
end

def hosts
  get(:infra, :hosts)
end

def protocol
  get(:workload, :protocol)
end

def target
  get(:workload, :target)
end

def [](key)
  get(key)
end

def []=(key, value)
  @data[key] = value
end

private

def load_json(path)
  result = JSON.parse(File.read(path), symbolize_names: true)
  rescue Errno::ENOENT
    @logger.error "workload file '#{path}' not found"
  rescue Errno::EACCESS
    @logger.error "workload file '#{path}' not accessible"
  rescue JSON::ParserError
    @logger.error "workload file '#{path}' contains invalid JSON"

  result
end

def check
  require_relative @schema
  SCHEMA.call(@data)
end

def get(*keys)
  value = @data.dig(*keys)
  @logger.error "missing configuration parameter '#{keys.join('.')}'" if value.nil?
  value
end


end
