require_relative './utilities'

class Hook < FlexCartesian
  
def initialize(logger, config, target)
  super(config.parameters.merge!({ iteration: (1..config[:workload][:iterations]).to_a}))
  @logger = logger
  @config = config
  @target = target
  counter_set
  setup
end

private

def counter_set
  @counter = 0
  @total = self.size
  self.func(:add, :counter, hide: true) do |v|
    @counter += 1
    @logger.info "invocation #{@counter} of #{@total}: #{self.dimensions(v, separator: ' ')}"
  end
end

def setup
  # must be implemented in child class of your hook
end

end
