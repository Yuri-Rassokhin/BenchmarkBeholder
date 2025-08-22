module Platform

def self.metrics(logger: , target: , space: , result: , compute: true, storage: true, os: true, gpu: true)
  @logger, @target, @space, @result = logger, target, space, result
  self.metrics_compute if compute
  self.metrics_storage if storage
  self.metrics_os if os
  self.metrics_gpu if gpu
end

def self.metrics_gpu
  gpu_count = `lspci | grep -i nvidia`.lines.count

  @space.func(:add, "gpu_count".to_sym) { gpu_count }

  (1..gpu_count).each do |i|

    model = `nvidia-smi --query-gpu=name --format=csv,noheader -i #{i-1}`.chomp
    @space.func(:add, "gpu#{i}_model".to_sym) { model }

    memory = `nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i #{i-1}`.chomp.to_i
    @space.func(:add, "gpu#{i}_memory".to_sym) { memory }

    @space.func(:add, "gpu#{i}_utilization".to_sym) { `nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits -i #{i-1}`.chomp.to_f }
  end
end

def self.metrics_compute
  @space.func(:add, :cpu_load) { cpu_load }
  @space.func(:add, :cloud_platform) { platform }
  @space.func(:add, :compute_shape) { shape(platform) }
  @space.func(:add, :cpu_arch) { cpu_arch }
  @space.func(:add, :cpu_model) { cpu_model }
  @space.func(:add, :cpu_cores) { cpu_cores }
  @space.func(:add, :cpu_ram) { cpu_ram }
end

def self.metrics_storage
  s = @target
  @logger.error "storage #{s} is not supported" unless (File.blockdev?(s) or File.file?(s))

  @space.func(:add, :storage_device) { |v| main_device(s) }

  if File.file?(s)
    tmp = scan_device(s)
    @space.func(:add, :storage_fs) { |v| tmp[:filesystem] }
    @space.func(:add, :storage_fs_block_size) { tmp[:filesystem_block_size] }
    @space.func(:add, :storage_fs_mount_options) { |v| "\"#{tmp[:filesystem_mount_options]}\"" }
    @space.func(:add, :storage_type) { |v| tmp[:type] }
    @space.func(:add, :storage_volumes) { |v| tmp[:volumes].join(' ') }

    tmp[:volumes].each do |volume|
      @space.func(:add, "#{volume}-load}".to_sym) { io_load(volume) }
    end
  end
end

def self.metrics_os
  @space.func(:add, :kernel) { @result[:kernel] ||= kernel_release }
  @space.func(:add, :os_release) { @result[:os_release] ||= os_release }
end

def self.scan_device(src)
  #raise "Incorrect path or not a regular file '#{src}'" unless File.file?(src)

  # Get the mount point, filesystem, and device where the file resides
  mount_point = run_sudo("df --output=target #{src} | tail -1")
  filesystem = run_sudo("df --output=fstype #{src} | tail -1")
  device = run_sudo("df --output=source #{src} | tail -1")
  type = ""
  volumes = ""

  # Detect if the device is LVM or RAID
  if device.include?("/dev/mapper")
    # For LVM, use pvs to find the underlying physical volumes
    type = "LVM"
    vg_name = run_sudo("lvdisplay #{device} | grep 'VG Name' | awk '{print $3}'")
    physical_volumes = run_sudo("pvs --noheadings -o pv_name --select vg_name=#{vg_name}")
    volumes = physical_volumes
    aggregated = true
  elsif device.include?("/dev/md")
    # For RAID, use mdadm to get the underlying devices
    type = "RAID"
    raid_devices = run_sudo("mdadm --detail #{device} | grep '/dev/' | awk '{print $7}'")
    volumes = raid_devices
    aggregated = true
  else
    # For regular block devices, just show the device
    type = "physical device"
    aggregated = false
  end
  {
    filesystem: "#{filesystem}",
    filesystem_block_size: filesystem_block_size(main_device(src), filesystem),
    filesystem_mount_options: filesystem_mount_options(main_device(src)),
    type: "#{type}",
    volumes: "#{volumes}".split,
    aggregated: aggregated,
  }
end

def self.shape(platform)
  case platform
  when "OCI"
    raw = `curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | grep -iw shape | awk '{print $2}' | sed 's/"//g' | sed 's/,//'`
    return raw.strip.gsub(/["",]/, '') if raw != ""
  when "Azure"
    raw = `curl -s --connect-timeout 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | grep "vmSize" | awk '{ print $2 }'`
    return raw.strip.gsub(/["",]/, '') if raw != ""
  when "AWS"
    raw = `curl -s http://169.254.169.254/latest/meta-data/instance-type`
    return raw.strip.gsub(/["",]/, '')
    #if raw != "No such metadata item"
  else
    return "unknown"
  end
end

def self.platform
  raw = `curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | grep -iw shape | awk '{print $2}' | sed 's/"//g' | sed 's/,//'`
  return "OCI" if not raw.empty?

  raw = `curl -s --connect-timeout 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | grep "vmSize" | awk '{ print $2 }'`
  return "Azure" if not raw.empty?

  raw = `curl -s http://169.254.169.254/latest/meta-data/instance-type`
  return "AWS" if not raw.empty?

  "unknown"
end

def self.main_device(src)
    `df -h #{src} | tail -1 | sed -e 's/ .*$//'`.strip
end

def self.oci_bucket_exists?(bucket_name, namespace)
    require 'oci'
    config = OCI::ConfigFileLoader.load_config()
    object_storage = OCI::ObjectStorage::ObjectStorageClient.new(config: config)
    response = object_storage.list_objects(namespace, bucket_name)
    response
  end

  # OBSOLETE
  # Given OCI user OCID, return the user's compartment OCID, or root tenancy if the user has no a particular compartment
  def oci_get_compartment_id(user_ocid)
    config = OCI::ConfigFileLoader.load_config
    identity_client = OCI::Identity::IdentityClient.new(config: config)
    tenancy_id = config.tenancy
    compartments = identity_client.list_compartments(tenancy_id, compartment_id_in_subtree: true).data
    user_compartment = compartments.find { |comp| comp.id == tenancy_id }
    user_compartment ? user_compartment.id : nil
  end

  # OBSOLETE
  # In a given OCI compartment, check if a given string denotes an existing Object Storage bucket
  def oci_object_storage_bucket?(bucket_name, compartment)
    object_storage_client = OCI::ObjectStorage::ObjectStorageClient.new
    namespace = object_storage_client.get_namespace.data
    response = object_storage_client.list_buckets(namespace, compartment)
    bucket_names = response.data.map(&:name)
    bucket_names.include?(bucket_name)
end

  def self.os_release
    distro_name = "Unknown"
    distro_version = "Unknown"

    if File.exist?('/etc/os-release')
      File.readlines('/etc/os-release').each do |line|
        if line.start_with?('NAME=')
          distro_name = line.split('=')[1].strip.delete('"')
        elsif line.start_with?('VERSION=')
          distro_version = line.split('=')[1].strip.delete('"')
        end
      end
    else
      Dir.glob('/etc/*-release').each do |file|
        File.readlines(file).each do |line|
          if line.start_with?('NAME=')
            distro_name = line.split('=')[1].strip.delete('"')
          elsif line.start_with?('VERSION=')
            distro_version = line.split('=')[1].strip.delete('"')
          end
        end
      end
    end

  "#{distro_name} #{distro_version}"
  #    `lsb_release -si`.strip + " " + `lsb_release -sr`.strip
  end

  def self.kernel_release
    `uname -r`.strip
  end

  def self.cpu_arch
    `uname -m`.strip
  end

  def self.cpu_model
    `grep "model name" /proc/cpuinfo | sed -e 's/^.*: //' | head -n 1`.strip
  end

  def self.cpu_cores
    `grep processor /proc/cpuinfo | wc -l`.strip
  end

  def self.cpu_ram
    `grep -i memtotal /proc/meminfo | sed -e 's/MemTotal:[ ]*//' | sed -e 's/ kB//'`.strip
  end

  def self.filesystem(file)
    s_type = `stat -c "%F" #{file}`.strip
    case s_type
    when "regular file", "regular empty file"
      `df -T #{file} | tail -1 | awk '{print $2}'`.strip
    when "block special device"
      "N/A"
    else
#      "incorrect type of test target #{src}: #{s_type}" 
      nil
    end
  end

  def self.cpu_load
    (100 - cpu_idle)
  end

  def self.io_load(device)
  (100 - io_idle(device))
end

  def self.cpu_idle
    `mpstat 1 1 | tail -1 | awk 'NF>1{print $NF}' | sed -e 's/\\.[0-9]*$//'`.strip.to_f
  end

  def self.io_idle(device)
    dev = File.basename(device)
    `iostat -dx #{dev} | awk '/^#{dev}/ { print $NF }'`.strip.to_f
  end

  def self.filesystem_block_size(main_dev, filesystem)
  "" if main_dev.nil? || %w[tmpfs ramfs nfs NA].include?(filesystem)

  case filesystem
  when "ext2", "ext3", "ext4"
    `sudo tune2fs -l #{main_dev} | grep -i "block size" | awk '{print $3}'`.strip
  when "xfs"
    `xfs_info #{main_dev} | grep bsize | grep data | sed -e 's/^.*bsize=//' | awk '{print $1}'`.strip
  when "vboxsf"
    "NA"
  else
    @logger.warn "unsupported filesystem #{filesystem} on #{main_dev}"
    ""
  end
end

  def self.filesystem_mount_options(main_dev)
  `cat /proc/mounts | grep "#{main_dev}" | awk '{print $4}'`.strip
end

  def self.switch_scheduler(dev, filesystem, scheduler, raid_members, aggregated)
  return if %w[ramfs tmpfs nfs fuse.glusterfs].include?(filesystem) || scheduler == "N/A"

  dev_name = File.basename(dev)
  # If a physical device
  if not aggregated
    return unless File.exist?("/sys/block/#{dev_name}/queue/scheduler")
    `sudo bash -c "echo #{scheduler} > /sys/block/#{dev_name}/queue/scheduler"`
    `cat /sys/block/#{dev_name}/queue/scheduler`.strip
  else
    # If LVM or RAID, /sys/block configuration of IO scheduling may differ between parent and children
    # To stay safe, we attempt to set it for all
    `sudo bash -c "echo #{scheduler} > /sys/block/#{dev_name}/queue/scheduler"` if File.exists?("/sys/block/#{dev_name}/queue/scheduler")
    raid_members.each do |drive|
      if drive.include?("nvme") && `cat /sys/module/nvme_core/parameters/multipath`.strip == "Y"
        drive = drive.gsub(/(\d)/, 'c\1')
      end
      dev = File.basename(drive)
      parent = dev.gsub(/\d+$/, '')
      `sudo bash -c "echo #{scheduler} > /sys/block/#{parent}/#{dev}/queue/scheduler"` if File.exists?("/sys/block/#{parent}/#{dev}/queue/scheduler")
#      `cat /sys/block/#{dev}/queue/scheduler on #{dev}`
    end.join(" ")
  end
end

# Run shell command as root and capture output
def run_sudo(cmd)
  result = `sudo #{cmd}`
  result.strip
end

def self.check_raid(main_dev_name)
  raid_level = `grep #{main_dev_name} /proc/mdstat | tr ' ' '\n' | grep raid | sed -e 's/raid//'`.strip
  if raid_level.empty?
    { raid_members: "n/a", raid_members_amount: 1, storage_type: "\"Single Drive\"" }
  else
    raid_members = `grep #{main_dev_name} /proc/mdstat | tr ' ' '\n' | sed -n 's/\\[.*//p'`.strip
    raid_members_amount = raid_members.lines.count
    if raid_members_amount.zero?
      error("#{src} qualifies as RAID but has no active members")
    else
      { raid_members: raid_members, raid_members_amount: raid_members_amount, storage_type: "RAID#{raid_level}" }
    end
  end
end

def self.get_cpu_consumption
  `echo "scale=3;(100 - $(mpstat | tail -n 1 | awk '{print $12}'))/100" | bc`.strip
end

def self.get_storage_consumption(device, main_dev)
  if device == "RAM"
    -1
  elsif device == "NFS"
    `nfsiostat | head -5 | tail -1 | awk '{print $1}'`.strip
  else
    `iostat #{main_dev} | grep #{File.basename(main_dev)} | awk '{print $2}'`.strip
  end
end

end
