#!/usr/bin/ruby

require 'fileutils'
require 'open3'
require 'tempfile'
require 'date'
require 'flex-cartesian'

require './sources/infrastructure/utilities_general.rb'
require './sources/options.rb'
require './sources/approach/target.rb'
require './sources/misc/ssh_sharing.rb'

require_relative './sources/config.rb'
require_relative './sources/head.rb'
require_relative './sources/nodes.rb'
require_relative './sources/global-ruby.rb'
require_relative './sources/hook.rb'
require_relative './sources/log.rb'

series = Time.now.to_i.to_s # start counting total processing time

logger = Log.new # logger for the entire application

options = Options.new(logger, ARGV) # parse CLI options

logger.info "Starting series #{series}"

config = Config.new(logger, options.workload) # parse the workload configuration file
config[:parameters][:host] = options.hosts # add benchmark nodes from CLI
config[:parameters][:series] = series # add unique series ID

Head.check(logger, config) # head node checks such as consistent hook files
Nodes.check(logger, config) # benchmark node checks such as SSH availability, actor presence, etc

target = Target.new(logger, config)

# create Benchmarking class using its child named after the hook
require_relative "./sources/hooks/#{config.hook}/benchmarking"
space = Benchmarking.new(logger, config, target)

logger.info "Number of invocations: #{space.size}"

#  Global.run(binding, h, space.method(:func), :run)

space.func(:run)

logger.info "Series #{series} completed"

space.output(format: :csv, file: "./log/bbh-#{config.hook}-#{series}-result.csv")
space.output(colorize: true, align: true)

