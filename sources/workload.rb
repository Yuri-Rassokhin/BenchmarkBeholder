require_relative './utilities'

class Workload < FlexCartesian
  
def initialize(logger: , config: )
  super config.sweep
  @logger = logger
  @config = config
  @workload_name = @config.workload
  check_consistency
  counter_set
  require_relative "./hooks/#{@workload_name}/metrics"
  setup
end

def preparation
  @logger.info "Running preparations before benchmarking"
  prepare
end

private

def check_consistency
  workloads = Dir.entries("./sources/hooks") - %w[. ..]
  @logger.error "unknown workload '#{@workload}'" if !workloads.include?(@workload_name)

  wl = "./sources/hooks/#{@workload_name}/schema.rb"
  @logger.error "incorrect integration of '#{@workload_name}', workload schema '#{wl}' is missing" if !File.exist?(wl)

  bm = "./sources/hooks/#{@workload_name}/metrics.rb"
  @logger.error "incorrect integration of '#{@workload_name}', workload metrics '#{bm}' are missing" if !File.exist?(bm)
end

def counter_set
  @time_start = Time.now.to_i
  @counter = 0
  @total = self.size
  self.func(:add, :counter, hide: true) do |v|
    @counter += 1
    @done = (@counter*100/@total.to_f).to_i
    @logger.info " #{@workload_name} #{@counter}/#{@total} (#{@done}%): #{self.dimensions(v, separator: ' ')}"
  end
end

def prepare
end

def setup
end

end
