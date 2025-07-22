
module Head
  module_function

def self.check(logger, config)
  self.check_hook(logger, config.name)
end

def self.check_hook(logger, hook)
  hooks = Dir.entries("./sources/hooks") - %w[. ..]
  logger.error "unknown workload '#{hook}'" if !hooks.include?(hook)
  logger.error "incorrect integration of '#{hook}', invocation file is missing" if !File.exist?("./sources/hooks/#{hook}/invocation.rb")
  logger.error "incorrect integration of '#{hook}', parameters file is missing" if !File.exist?("./sources/hooks/#{hook}/parameters.rb")
end

end

