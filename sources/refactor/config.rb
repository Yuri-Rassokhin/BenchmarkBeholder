require 'json'
require 'dry-validation'

class Config

def initialize(name)
  @config = "./workloads/#{name}.json"
  @parameters = "./hooks/#{name}/parameters.rb"
  result = check
  puts "Parameter errors:\n - " + result.errors(full: true).map(&:text).join("\n - ") if !result.success?
end

private

def check
  require_relative @parameters
  SCHEMA.call(
    JSON.parse(File.read(@config), symbolize_names: true)
  )
end



end
