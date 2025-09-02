class Config

def initialize(logger, config_path)
  @logger = logger
  @data = preprocess(load_json(config_path))
  @schema = "./hooks/#{workload}/schema.rb"
  check_schema
end

def workload
  get :workload
end

def target
  @data[:startup][:target]
end

def sweep
  get :sweep
end

def startup
  get :startup
end

def [](key)
  get(key)
end

def []=(key, value)
  @data[key] = value
end

def defined?(*keys)
  @data.dig(*keys) != nil
end

private

# umbrella method for any preprocessing of workload file
def preprocess(json)
  Utilities.json_unscale(@logger, json)
end

def load_json(path)
  @logger.info "workload file #{path}"
  result = JSON.parse(File.read(path), symbolize_names: true)
  rescue Errno::ENOENT
    @logger.error "workload file '#{path}' not found"
    exit 0
  rescue Errno::EACCES
    @logger.error "workload file '#{path}' not accessible"
    exit 0
  rescue JSON::ParserError
    @logger.error "workload file '#{path}' contains invalid JSON"
    exit 0
  result
end

def check_schema
  if not File.exist?("./sources/" + @schema)
    @logger.error "workload schema '#{"./sources/" + @schema}' is missing"
    exit 0
  end
  require_relative @schema # load semantic schema of parameters
  result = Schema.validate.call(@data) # apply the schema

  if !result.success?
    result.errors.each do |error|
      path = error.path.reject { |p| p.is_a?(Integer) }.join('.')
      value = error.path.reduce(@data) do |acc, key|
        acc.is_a?(Hash) ? acc[key] : acc[key] rescue nil
      end
      @logger.warn "Incorrect value '#{value}' in #{path}, #{error.text}"
    end
  end
end

def get(*keys)
  value = @data.dig(*keys)
  @logger.error "missing configuration parameter '#{keys.join('.')}'" if value.nil?
  value
end

end
