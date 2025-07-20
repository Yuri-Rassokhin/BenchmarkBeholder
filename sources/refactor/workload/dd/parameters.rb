require 'json'
require 'dry-validation'

class Config

def initialize(name)
  @path = "./workloads/#{name}.json"
  result = check
  puts "Parameter errors:\n - " + result.errors(full: true).map(&:text).join("\n - ") if !result.success?
end

private

def check
  schema = Dry::Schema.JSON do

    required(:workload).hash do
      required(:protocol).filled(:string, included_in?: %w[file http http])
      required(:actor).filled(:string)
      required(:target).filled(:string)
      required(:iterations).filled(:integer, gt?: 0)
    end

    required(:parameters).hash do
      required(:schedulers).array(:string, min_size?: 1, included_in?: %w[none bfq deadline-mq kyber])
      required(:size).array(:integer, min_size?: 1)
      required(:operations).array(:string, min_size?: 1, included_in?: %w[read write randread randwrite])
    end

  end
  schema.call(
    JSON.parse(File.read(@path), symbolize_names: true)
  )
end



end
