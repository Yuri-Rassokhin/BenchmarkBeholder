
module Nodes
  module_function

  require './sources/infrastructure/utilities_general.rb'

def self.check(logger, config)
  self.check_hook(logger, config.hook)
  self.check_ssh_persistance(logger)
  self.check_another_instance(logger, config.hosts)
  self.check_dependencies(logger, config.hosts)
  self.check_actor(logger, config)
  self.check_cpu_idle(logger, config)
  self.check_storage_idle(logger, config)
end

private

def self.check_hook(logger, hook)
  hooks = Dir.entries("./sources/hooks") - %w[. ..]
  logger.error "unknown workload '#{hook}'" if !hooks.include?(hook)
  logger.error "incorrect integration of '#{hook}', invocation file is missing" if !File.exist?("./sources/hooks/#{hook}/invocation.rb")
  logger.error "incorrect integration of '#{hook}', parameters file is missing" if !File.exist?("./sources/hooks/#{hook}/parameters.rb")
end

def self.check_ssh_persistance(logger)
  logger.info "checking SSH persistance on central node" # maximize SSH performance
  ssh_sharing_enable
end

def self.check_ssh_availability(logger, hosts)
  logger.info "checking SSH availability of benchmark nodes"
  hosts.each do |host|
    logger.error("#{agent.error}") if !agent.available?(host)
  end
end

def self.check_another_instance(logger, hosts)
  logger.info "checking if another BBH instance is running on benchmark nodes"
  hosts.each do |host|
    logger.error("another instance of BBH is running on '#{host}'") if Global.run(binding, host, :bbh_running?)
  end
end

def self.check_dependencies(logger, hosts)
  logger.info "checking dependencies on benchmark nodes"
  hosts.each do |host|
    [ "ruby", "curl", "mpstat", "iostat" ].each { |tool| logger.error("'#{tool}' is missing ") if not Global.run(binding, host, :file_exists?, "#{tool}") }
  end
end

# actor is an executable file WITHOUT path, it's a madatory option
# BBH seeks actor in A). its integration directory
# B). system-wide using 'which'
# This approach allows to flexibly use multiple specialized actors for one workload as well as a system actor
def self.check_actor(logger, config)
  logger.info "checking actor on benchmark nodes"
  actor = config.actor
  config.hosts.each do |host|
    found = Global.run(binding, host, :actor_exists?, actor)
    logger.error("actor '#{actor}' is missing on the node '#{host}'") if not found
  end
end

def self.check_cpu_idle(logger, config)
  logger.info "checking if CPU cores are idle on benchmark nodes"
  config.hosts.each do |host|
    logger.error("CPU utilization >= 10% on '#{host}', no good for benchmarking") if Global.run(binding, host, :cpu_idle) < 90
  end
end

def self.check_storage_idle(logger, config)
  logger.info "checking if IO subsystem is idle on benchmark nodes"
  config.hosts.each do |host|
    logger.error("IO utilization >= 10% on '#{host}', no good for benchmarking") if Global.run(binding, host, :io_idle) < 90
  end
end



end
