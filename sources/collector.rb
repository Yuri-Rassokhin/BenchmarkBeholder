
require 'mysql2'
require 'open3'

class Collector < Agent

  attr_reader :src, :number_installed_gpus, :host, :release, :kernel, :arch, :cpu, :cores, :ram, :main_dev, :main_dev_name, :filesystem, :raid_info, :fs_block_size, :shape, :device

# Common parameters from the server node
#series = ARGV[0]
#host = ARGV[1]
#mode = ARGV[2]
#benchmark = ARGV[3]
#agenthook = ARGV[5]
#schedulers = ARGV[6]
#warning_log = ARGV[7]
#hook_database = ARGV[8]
 
def initialize(config, url, mode_raw, logger, series)

  @error_counter = 0
  @series = series
  @user = config.get(:infra_user)
  @src = config.get(:startup_media)
  super(@user, url)
  @logger = logger
  @url = url
  @password = nil
  @number_installed_gpus = run!(:count_gpu)
  @host = run!(:hostname)
  @release = run!(:os_release)
  @kernel = run!(:kernel_release)
  @arch = run!(:cpu_arch)
  @cpu = run!(:cpu_model)
  @cores = run!(:core_count)
  @ram = run!(:cpu_ram_amount)
# Temp files to accumulate benchmark output before pushing it to database
#output = Tempfile.new
#error = Tempfile.new
#benchmark_log = Tempfile.new(["bbh-benchmark-log-#{series}", nil], '/tmp')
#sql_log = Tempfile.new(["bbh-sql-log-#{series}", nil], '/tmp')

  # Main execution
  @main_dev = run!(:main_device, @src)
  @main_dev_name = File.basename(@main_dev)
  @main_dev = File.basename(@src) if @main_dev == "udev"
  @filesystem = run!(:get_filesystem, @src)
  @raid_info = run!(:check_raid, @main_dev_name)
  @fs_block_size = run!(:get_filesystem_block_size, main_dev, filesystem)
  @fs_mount_options = get_filesystem_mount_options(main_dev)
  $shape, @subshape = run!(:guess_shape)
  @device = case filesystem
           when "ramfs", "tmpfs" then "RAM"
           when "nfs" then "NFS"
           when "fuse.glusterfs" then "GlusterFS"
           else main_dev
           end
  @gds_supported = run!(:check_gds, @filesystem)
  @gpu_info = run!(:get_gpu_consumption, @number_installed_gpus)
  @cpu_consumption = run!(:get_cpu_consumption)
  @storage_consumption = run!(:get_storage_consumption, @device, @main_dev)
  $mode = ( mode_raw == "single" ? "a single" : mode_raw )
  $media = ( @filesystem == "N/A" ? "raw device #{@src}" : @filesystem )
  @get_nvidia_versions = run!(:get_nvidia_versions)

  @desc = eval('"' + config.get(:series_description) + '"')

  #if File.readlines(warning_log).size > 0
  #  printf '%-70s', "Checking warnings #{warning_log}"
  #  puts "[WARN]"
  #end

#  load hook_database
#  load agenthook

end

def launch
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

def completed
  if @error_counter == 0
    puts "Series #{@series} completed"
  else
    puts "Series #{@series} completed with errors"
  end
end
  #File.delete(conf_file)

private

def extract()
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

def push()
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

end


