require_relative './utilities'

class Hook < FlexCartesian
  
def initialize(logger, config, target)
  super(config.parameters.merge!({ iteration: (1..config[:workload][:iterations]).to_a}))
  @logger = logger
  @config = config
  @target = target
  @hook = @config[:workload][:hook]
  counter_set
  setup
  load "./sources/hooks/#{@hook}/metrics.rb"
end

#require_relative "../#{@config[:workload][:hook]}/metrics.rb"

private

def counter_set
  @time_start = Time.now.to_i
  @counter = 0
  @total = self.size
  self.func(:add, :counter, hide: true) do |v|
    @counter += 1
    @done = (@counter*100/@total.to_f).to_i
    @logger.info " #{@hook} #{@counter}/#{@total} (#{@done}%): #{self.dimensions(v, separator: ' ')}"
  end
end

def setup
  Metrics.setup(self, @logger, @config, @target)
end

end
