#!/usr/bin/env ruby

require 'open3'

def note(message)
  printf '%-70s', message
end

def noted
  puts "[ OK ]"
end

def error(message)
  puts "ERROR #{message}, exiting"
  exit 1
end

def warning(message)
  puts "WARNING #{message}"
end

user = ENV['USER']
hosts = ENV['HOSTS'].split
src = ENV['SRC']
conf_file = ENV['CONF_FILE']

# Note function to check if the source exists
note "source #{src} exists"
hosts.each do |host|
  output, status = Open3.capture2("ssh -o StrictHostKeyChecking=no #{user}@#{host} sudo test -f #{src} && echo 'OK'")
  error("source #{src} missing") if output.strip != 'OK'
end
noted

# Check access rights to the source
note "access rights to source #{src}"
hosts.each do |host|
  output, status = Open3.capture2("ssh -o StrictHostKeyChecking=no #{user}@#{host} sudo test -w #{src} && echo 'OK'")
  error("user '#{user}' has no write access to #{src}") if output.strip != 'OK'
  output, status = Open3.capture2("ssh -o StrictHostKeyChecking=no #{user}@#{host} sudo test -r #{src} && echo 'OK'")
  error("user '#{user}' has no read access to #{src}") if output.strip != 'OK'
end
noted

# Check GPU peer memory
note "GPU peer memory"
hosts.each do |host|
  output, status = Open3.capture2("ssh -o StrictHostKeyChecking=no #{user}@#{host} sudo lsmod | grep nvidia_peermem")
  warning("peer GPU memory isn't enabled") if output.strip.empty?
end
noted

# Check GPU filesystem integration
note "GPU filesystem integration"
hosts.each do |host|
  output, status = Open3.capture2("ssh -o StrictHostKeyChecking=no #{user}@#{host} sudo lsmod | grep nvidia_fs")
  error("GPU filesystem integration isn't enabled, GDS isn't operational") if output.strip.empty?
end
noted

# Check benchmark-specific parameters
note "benchmark-specific parameters"
error("operation(s) missing in configuration #{conf_file}") if ENV['OPERATIONS'].nil? || ENV['OPERATIONS'].empty?
error("GPU data transfer mode is missing in configuration #{conf_file}") if ENV['GPU_MODES'].nil? || ENV['GPU_MODES'].empty?
error("source is missing in configuration #{conf_file}") if ENV['SRC'].nil? || ENV['SRC'].empty?
if ENV['JOBS_FROM'].nil? || ENV['JOBS_TO'].nil? || ENV['INCREMENT'].nil?
  error("range of processes is incorrect in configuration #{conf_file}")
end
error("block size is missing in configuration #{conf_file}") if ENV['BLOCK_SIZE'].nil? || ENV['BLOCK_SIZE'].empty?
noted

# TODO: Check correct names of operations and correct values of GPU modes


