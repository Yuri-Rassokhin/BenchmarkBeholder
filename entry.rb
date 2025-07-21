#!/usr/bin/ruby

require 'fileutils'
require 'open3'
require 'tempfile'
require 'date'
require 'method_source'
require 'mysql2'
require 'net/http'

require './sources/infrastructure/utilities_general.rb'
require './sources/logger.rb'
require './sources/options.rb'
require './sources/database/database.rb'
#require './sources/distributed/transfer.rb'
require './sources/approach/target.rb'
require './sources/launch.rb'
require './sources/misc/ssh_sharing.rb'

require_relative './sources/refactor/config.rb'
require_relative './sources/refactor/preparation.rb'
require_relative './sources/refactor/global-ruby.rb'



series = Time.now.to_i.to_s # start counting total processing time

logger = CustomLogger.new(series) # logger for the entire application
options = Options.new(logger, ARGV) # parse CLI options

if options.mode == "user"
  database = Database.new(logger)
  database.user_manage(options.user)
  exit 0
end

config = Config.new(logger, options.workload) # parse the workload configuration file
options.check_hook(config.name) # check if hooks directory exists and contains mandatory files
config[:infra] = { :hosts => options.hosts } # hosts to run workload

Preparation.run(logger, config)

