#!/usr/bin/ruby

require 'fileutils'
require 'open3'
require 'tempfile'
require 'date'
require 'method_source'

require './sources/logger.rb'
require './sources/basic/validated_number.rb'
require './sources/basic/validated_string.rb'
require './sources/config/generic_config.rb'
require './sources/config/general_config.rb'
require './sources/distributed/agent.rb'
require './sources/parser.rb'
require './sources/database/projects.rb'
require './sources/database/benchmarks.rb'
require './sources/collector.rb'
require './sources/distributed/transfer.rb'

version = "4.0"
series = Time.now.to_i.to_s

logger = CustomLogger.new(series)
parser = Parser.new(version, logger, ARGV[0])
db_projects = Projects.new()
config = GeneralConfig.new(ARGV[0], db_projects.codes)
parser.check(config.get(:series_benchmark))
db_benchmarks = Benchmarks.new(config.get(:series_benchmark))

agent = Agent.new(config.get(:infra_user), nil)

config.get(:infra_hosts).split.each do |host|
  logger.note("availability of the node '#{host}'") do
    logger.error("'#{host}' is unavailable") if !agent.available?(host)
  end
end

#add filesystem functionality to the agent
#agent.add(:get_filesystem) do |args|
#  logger.note ("type of source #{src}") do
#    get_filesystem(args)
#  end
#end

# check if config path exists on the nodes
config.get(:infra_hosts).split.each do |host|
  logger.note("path on '#{host}'") do
    logger.error("#{config.get(:path)} is missing on '#{host}'") if !agent.run(host, :dir_exists?, config.get(:startup_path))
    end
end

# check if benchmark source exists on the nodes
config.get(:infra_hosts).split.each do |host|
  logger.note("source on '#{host}'") do
    logger.error("#{config.get(:startup_src)} is missing on '#{host}'") if !agent.run(host, :file_exists?, config.get(:startup_src))
    end
end

# TODO: this should execute in parallel, if explicitly mentioned
# check if filesystem is known on the nodes
config.get(:infra_hosts).split.each do |host|
  logger.error("can't determine filesystem on '#{config.get(:startup_src)}'") if !agent.run(host, :get_filesystem, config.get(:startup_src))
end

# enable all available kernel IO schedulers on the nodes
logger.note("available kernel IO schedulers") do
  config.get(:infra_hosts).split.each do |host|
    %w[mq-deadline kyber bfq none].each do |scheduler|
      `ssh -o StrictHostKeyChecking=no #{config.get(:infra_user)}@#{host} sudo modprobe -q #{scheduler}`
    end
  end
end

logger.note("specification of kernel IO schedulers") do
  config.get(:iterate_schedulers).split.each do |scheduler|
    system_schedulers = `cat /sys/block/sda/queue/scheduler`.strip + " N/A"
    logger.error("unknown IO scheduler '#{scheduler}'") unless system_schedulers.include?(scheduler)
  end
end

config.get(:infra_hosts).split.each do |host|
  logger.note("if the node '#{host}' has idle CPU") do
    logger.error("CPU utilization >= 10%, no good for benchmarking") if agent.run(host, :cpu_idle) < 90
  end
  logger.note ("if the node '#{host}' has idle storage") do
    logger.error("IO utilization >= 10%, no good for benchmarking") if agent.run(host, :io_idle) < 90
  end
end

logger.note("path to benchmark") do
  if !config.get(:startup_path) or config.get(:startup_path).empty?
    logger.warning("benchmark path unspecified, defaults to ./")
    config.set(:startup_path, "./")
  end
end

#$hosts.each do |host|
#  $logger.note("benchmark agent on the node '#{host}'") do
#    `scp -q #{generic_launcher} #{local_hook} #{conf_file} #{warning_log.path} #{hook_database} #{$user}@#{host}:/tmp/`
#  end
#end

collector = Hash.new
# depending on benchmark, load a proper config and define its class for the use later
case config.get(:series_benchmark)
  when "detectron2training" then class_needed = "Detectron2Training"
  else logger.fatal("unknown benchmark")
end

require "./sources/hooks/#{class_needed.downcase}/#{class_needed.downcase}.rb"
 require "./sources/hooks/#{class_needed.downcase}/#{class_needed.downcase}-config.rb"

# create benchmark-specific config and merge the general config into it
full_config = Object.const_get("#{class_needed}Config").new(ARGV[0])
full_config.merge(config)

# assign collector, aka permanent agent, for each node
mode = config.get(:infra_hosts).split.size > 1 ? "multiple" : "single"
logger.note("agent on each node") do
  config.get(:infra_hosts).split.each do |host|
    collector[host] = Object.const_get(class_needed).new(full_config, host, mode, logger, series)
  end
end

logger.note("launch on the node(s)") do
  config.get(:infra_hosts).split.each do |host|
    puts collector[host].run(host, :launch, full_config.merge({ iteratable_size: full_config.iteratable_size }))
#    `ssh -o StrictHostKeyChecking=no #{config.get(:infra_user)}@#{host} #{remote_generic_launcher} #{series} #{host} "#{mode}" "#{hook}" "#{remote_conf_file}" #{remote_hook} "#{$schedulers}" #{warning_log.path} #{remote_hook_database} #{log_dir}`
  end
end

logger.info("#{config.get(:series_benchmark)} series #{series} has launched, check logs on #{config.get(:infra_hosts).split.join(', ')}")

