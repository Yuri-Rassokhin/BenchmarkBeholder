
module Head
  module_function

def self.check(logger, config)
  self.check_hook(logger, config.hook)
end

def self.check_hook(logger, hook)
  hooks = Dir.entries("./sources/hooks") - %w[. ..]
  logger.error "unknown workload '#{hook}'" if !hooks.include?(hook)
  wl = "./sources/hooks/#{hook}/workload.rb"
  logger.error "incorrect integration of '#{hook}', workload schema '#{wl}' is missing" if !File.exist?(wl)
  bm = "./sources/hooks/#{hook}/benchmarking.rb"
  logger.error "incorrect integration of '#{hook}', benchmarking file '#{bm}' is missing" if !File.exist?(bm)
end

end

