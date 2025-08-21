require_relative './utilities'

class Workload < FlexCartesian
  attr_accessor :series

def initialize(logger: , config: )
  super config.sweep
  @logger = logger
  @config = config
  @workload_name = @config.workload
  @series = Time.now.to_i.to_s
  @result = {}
  load_metrics
  counter_set
  setup
end

def preparation
  if self.class.private_instance_methods(false).include?(:prepare)
    @logger.info "running preparations for the benchmarking"
    prepare
  else
    @logger.info "nothing to prepare for the benchmarking"
  end
end

def benchmark
  @logger.info "Starting series #{@series}"
  func(:run)
  @logger.info "Series #{@series} completed"
end

private

def setup
  @logger.info "no metrics specified, nothing to do, exiting"
  exit 0
end

def load_metrics
  metrics_path = "./sources/hooks/#{@workload_name}/metrics.rb"
  @logger.error "incorrect integration of '#{@workload_name}', workload metrics '#{metrics_path}' are missing" unless File.exist?(metrics_path)
  require metrics_path
  load metrics_path
end

def counter_set
  @time_start = Time.now.to_i
  @counter = 0
  @total = self.size
  self.func(:add, :counter, hide: true, order: :first) do |v|
    @counter += 1
    @done = (@counter*100/@total.to_f).to_i
    @logger.info " #{@workload_name} #{@counter}/#{@total} (#{@done}%): #{self.dimensions(v, separator: ' ')}"
  end
  self.func(:add, :store, hide: true, order: :last) do |v|
    @logger.info " => #{@result.inspect}"
    @result = {}
  end
end

end
