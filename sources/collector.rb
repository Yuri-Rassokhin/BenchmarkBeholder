
require 'mysql2'
require 'open3'

class Collector < Agent

  attr_reader :infra_static

def initialize(config, url, mode_raw, logger, series, target)
  @config = config
  user = config.get(:infra_user)
  super(user, url)
  @logger = logger

  platform = config.get(:infra_platform)
  shape = run!(:guess_shape, platform)
  src = config.get(:startup_target)
  main_dev = run!(:main_device, src)
#  main_dev = File.basename(src) if main_dev == "udev"
#  main_dev_name = File.basename(main_dev)
#  filesystem = run!(:get_filesystem, src)
  if target.has_device?
    device_info = run!(:check_device, src)
  else
    device_info = { filesystem: "NA", type: "NA", members: "NA", aggregated: false }
  end
  filesystem = device_info[:filesystem]
  type = device_info[:type]
  members = device_info[:members].split

#  puts "src: #{src}, main_dev: #{main_dev}, raid_info: #{raid_info}"
#  puts "fs: #{filesystem}"
  @infra_static = {
    series: series,
    user: user,
    src: src,
    url: url,
    password: nil,
    number_installed_gpus: run!(:count_gpu),
    host: run!(:hostname),
    release: run!(:os_release),
    kernel: run!(:kernel_release),
    arch: run!(:cpu_arch),
    cpu: run!(:cpu_model),
    cores: run!(:core_count),
    ram: run!(:cpu_ram_amount),
    main_dev: main_dev,
#    main_dev_name: main_dev_name,
    filesystem: filesystem,
    raid_members: members,
    raid_members_amount: members.size,
    root_dev: device_info[:aggregated] ? get_aggregated_root_dev(main_dev) : get_root_dev(main_dev),
    aggregated: device_info[:aggregated],
    storage_type: type,
    fs_block_size: run!(:get_filesystem_block_size, main_dev, filesystem),
    fs_mount_options: get_filesystem_mount_options(main_dev),
    shape: shape,
    subshape: "",
    device: case filesystem
           when "ramfs", "tmpfs" then "RAM"
           when "nfs" then "NFS"
           when "fuse.glusterfs" then "GlusterFS"
           else "NA"
           end,
    gds_supported: run!(:check_gds, filesystem),
#   gpu_info: run!(:get_gpu_consumption, @number_installed_gpus),
#   @cpu_consumption = run!(:get_cpu_consumption)
#   @storage_consumption = run!(:get_storage_consumption, @device, @main_dev)
    mode: mode_raw == "single" ? "a single" : mode_raw,
    target: filesystem == "N/A" ? "raw device #{src}" : filesystem,
    get_nvidia_versions: run!(:get_nvidia_versions),
    series_description: ""
  }
  @infra_static[:series_description] = description_eval(config.get(:series_description))

  launch_set
end

def launch(*args)
  puts("method 'launch' must be overridden")
  exit
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

# instantiate 'launch' method from the specificed hook
def launch_set
  hook = @config.get(:series_benchmark)
  input = File.expand_path("../sources/hooks/#{hook}/launch.rb", __dir__)
  require input
  mod = Object.const_get(:Launch)
  self.class.prepend(mod) # adds as instance method
end

# gets root device name for a given partiion; NOTE: it doesn't work with RAID/LVM
def get_root_dev(main_dev)
  File.basename(main_dev).gsub(/\d+$/, '')
end

def get_aggregated_root_dev(main_dev)
  `sudo lvs --segments -o +devices #{main_dev} | tac | head -1 | awk '{print $7}' | sed 's/[0-9].*$//'`
end

def description_eval(description)
  target = @infra_static[:target]
  mode = @infra_static[:mode]
  shape = @infra_static[:shape]
  eval("\"" + description + "\"")
end

def extract()
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

def push()
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

end


