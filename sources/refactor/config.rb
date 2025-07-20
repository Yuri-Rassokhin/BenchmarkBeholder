require 'json'
require 'dry-validation'

class Config

def initialize(config_path)
  @data = JSON.parse(File.read(config_path), symbolize_names: true)
  @name = @data[:workload][:name]
  @schema = "./hooks/#{@name}/parameters.rb"
  result = check
  if !result.success?
      result.errors.each do |error|
      path = error.path.reject { |p| p.is_a?(Integer) }
                 .join('.')

#      path = error.path.map { |p| p.is_a?(Integer) ? "[#{p}]" : p }.join('.').gsub('.[', '[')
      value = error.path.reduce(@data) do |acc, key|
        acc.is_a?(Hash) ? acc[key] : acc[key] rescue nil
      end
      puts "Incorrect value '#{value}' in #{path}, #{error.text}"
    end
  end
end

private

def check
  require_relative @schema
  SCHEMA.call(@data)
end



end
