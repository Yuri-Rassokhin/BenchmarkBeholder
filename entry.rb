#!/usr/bin/ruby

require 'fileutils'
require 'open3'
require 'tempfile'
require 'date'
require 'net/http'

require 'flex-cartesian'

require './sources/infrastructure/utilities_general.rb'
require './sources/logger.rb'
require './sources/options.rb'
require './sources/approach/target.rb'
require './sources/misc/ssh_sharing.rb'

require_relative './sources/refactor/config.rb'
require_relative './sources/refactor/head.rb'
require_relative './sources/refactor/nodes.rb'
require_relative './sources/refactor/global-ruby.rb'
require_relative './sources/refactor/launcher.rb'


series = Time.now.to_i.to_s # start counting total processing time

logger = CustomLogger.new(series) # logger for the entire application
options = Options.new(logger, ARGV) # parse CLI options

config = Config.new(logger, options.workload) # parse the workload configuration file
config[:parameters][:host] = options.hosts # add benchmark nodes from CLI
config[:parameters][:series] = series
Head.check(logger, config) # head node checks such as consistent hook files
Nodes.check(logger, config) # benchmark node checks such as SSH availability, actor presence, etc

target = Target.new(logger, config)

space = Launcher.new(logger, config)

logger.info "parameter unique combinations: #{space.size}"
logger.info "iterations for each combination: #{config.iterations}"
logger.info "total benchmark invocations: #{space.size * config.iterations}"

space.func(:run, progress: true, title: "[ DO ]")
space.output(format: :csv, file: "./result.csv")

