class Llama_rag < Collector

def initialize(config, url, mode, logger, series, target)
  super(config, url, mode, logger, series, target)
end

require_relative 'launch'

end
