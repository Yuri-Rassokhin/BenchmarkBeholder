#!/usr/bin/ruby

require 'fileutils'
require 'open3'
require 'tempfile'
require 'date'
require 'method_source'
require 'mysql2'

require './sources/logger.rb'
require './sources/basic/validation'
require './sources/config/generic_config.rb'
require './sources/config/general_config.rb'
require './sources/distributed/agent.rb'
require './sources/parser.rb'
require './sources/database/database.rb'
require './sources/collector.rb'
require './sources/distributed/transfer.rb'

series = Time.now.to_i.to_s
logger = CustomLogger.new(series)
parser = Parser.new(logger, ARGV)
database = Database.new
config = GeneralConfig.new(parser.conf_file, database.project_codes)
parser.check(config.get(:series_benchmark))

agent = Agent.new(config.get(:infra_user), nil)

config.get(:infra_hosts).each do |host|
  logger.note("availability of '#{host}'") do
    logger.error("'#{host}' is unavailable, #{agent.error}") if !agent.available?(host)
  end
end

# TODO: this check is benchmark-specific, such checks should perform automatically, as part of config checks
# check if config path exists on the nodes
config.get(:infra_hosts).each do |host|
  logger.note("benchmark executable on '#{host}'") do
    logger.error("#{config.get(:startup_executable)} is missing on '#{host}'") if !agent.run(host, :file_exists?, config.get(:startup_executable))
    end
end

# enable all available kernel IO schedulers on the nodes
logger.note("available kernel IO schedulers") do
  config.get(:infra_hosts).each do |host|
    %w[mq-deadline kyber bfq none].each do |scheduler|
      `ssh -o StrictHostKeyChecking=no #{config.get(:infra_user)}@#{host} sudo modprobe -q #{scheduler}`
    end
  end
end

logger.note("specification of kernel IO schedulers") do
  config.get(:iterate_schedulers).each do |scheduler|
    system_schedulers = `cat /sys/block/sda/queue/scheduler`.strip + " N/A"
    logger.error("unknown IO scheduler '#{scheduler}'") unless system_schedulers.include?(scheduler)
  end
end

unless parser.mode == :time
  config.get(:infra_hosts).each do |host|
    logger.note("if CPU is idle on '#{host}'") do
      logger.error("CPU utilization >= 10%, no good for benchmarking") if agent.run(host, :cpu_idle) < 90
    end
    logger.note ("if storage is idle on '#{host}'") do
      logger.error("IO utilization >= 10%, no good for benchmarking") if agent.run(host, :io_idle) < 90
    end
  end
end

#$hosts.each do |host|
#  $logger.note("benchmark agent on the node '#{host}'") do
#    `scp -q #{generic_launcher} #{local_hook} #{conf_file} #{warning_log.path} #{hook_database} #{$user}@#{host}:/tmp/`
#  end
#end

collector = Hash.new
# depending on benchmark, load a proper config and define its class for the use later
# TODO: this has to be a formuale where class_needed = uppercase variable
#case config.get(:series_benchmark)
#  when "detectron2training" then class_needed = "Detectron2Training"
#  when "dummy" then class_needed = "Dummy"
#  else logger.fatal("unknown benchmark")
#end

class_needed = config.get(:series_benchmark).capitalize

require "./sources/hooks/#{class_needed.downcase}/#{class_needed.downcase}.rb"
require "./sources/hooks/#{class_needed.downcase}/config.rb"

# create benchmark-specific config and merge the general config into it
full_config = Object.const_get("#{class_needed}config").new(parser.conf_file)
full_config.merge(config)

# first phase of description substituion - here we substitute all the variables from the config file
str = full_config.get(:series_description).gsub(/\#\{([^}]+)\}/) do |match|
  v = match[2..-2]
  if full_config.get?(v.to_sym)
    full_config.get(v.to_sym)
  else
    "\#\{" + "#{v}" + "}"
  end
end
full_config.set(:series_description, str)

# TODO: This parameter is benchmark-specific and may not be need for other benchmarks?..
# check if a media the benchmark is going to read from/write to exists on the nodes
full_config.get(:infra_hosts).each do |host|
  logger.note("media '#{full_config.get(:startup_media)}' on '#{host}'") do
    logger.error("#{full_config.get(:startup_media)} is missing on '#{host}'") if !agent.run(host, :file_exists?, full_config.get(:startup_media))
    end
end

# TODO: this should execute in parallel, if explicitly mentioned
# check if filesystem is known on the nodes
full_config.get(:infra_hosts).each do |host|
  logger.error("can't determine filesystem on '#{full_config.get(:startup_media)}'") if !agent.run(host, :get_filesystem, 
full_config.get(:startup_media))
end

# assign collector, aka permanent agent, for each node
# during creation, collector gathers all static data about its infrastructure
mode = full_config.get(:infra_hosts).size > 1 ? "multiple" : "single"
logger.note("agent on each node") do
  full_config.get(:infra_hosts).each do |host|
    collector[host] = Object.const_get(class_needed).new(full_config, host, mode, logger, series)
  end
end

# create database table for the requested benchmark, if it doesn't exist yet
load "./sources/hooks/#{class_needed.downcase}/schema.rb"
database.table_set(full_config.get(:series_benchmark), SCHEMA)

# Calculate size of the parameter space, and add it to the config for reporting purposes
parameter_space = full_config.iteratable_size
full_config.merge({ iteratable_size: parameter_space })
if parser.mode == :time
  logger.info("parameter space is #{parameter_space} invocations")
  exit 0
end

logger.note("launch on the node(s)") do
  full_config.get(:infra_hosts).each do |host|
    full_config.merge(collector[host].infra_static)
    collector[host].detach(host, :launch, full_config)
#    `ssh -o StrictHostKeyChecking=no #{config.get(:infra_user)}@#{host} #{remote_generic_launcher} #{series} #{host} "#{mode}" "#{hook}" "#{remote_conf_file}" #{remote_hook} "#{$schedulers}" #{warning_log.path} #{remote_hook_database} #{log_dir}`
  end
end

logger.info("#{full_config.get(:series_benchmark)} series #{series} has launched, check logs on '#{full_config.get(:infra_hosts).join(', ')}'")

