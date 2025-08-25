#module UtilitiesGeneral

  def oci_bucket_exists?(bucket_name, namespace)
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

  def args_show(args)
    puts args
  end

#  def out(status, output)
#    puts "[ " + status.to_s + ", #{output} ]"
#  end

  def actor_exists?(actor_file)
    file = actor_file.strip
    File.exist?("./hooks/#{actor_file}") || File.exist?(`which #{actor_file}`.strip)
  end

  def bbh_running?
    not `ps ax | grep "ruby /tmp/remote_method_call.rb" | grep -v grep`.strip.empty?
  end

  def block_device_exists?(file)
    File.blockdev?(`which #{file}`.strip)
  end

  def dir_exists?(file)
    `test -d #{file} && echo 1`.strip == "1"
  end

  def count_gpu

    def gpu?
      if `lspci | grep -i nvidia`.empty?
        return false
      elsif `which nvidia-smi`.empty?
        return false
      end
      true
    end

    if gpu?
      `nvidia-smi --list-gpus | wc -l`.strip
    else
      "0"
    end
  end

  def hostname
    `hostname -s`.strip
  end

  def os_release
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

  def kernel_release
    `uname -r`.strip
  end

  def cpu_arch
    `uname -m`.strip
  end

  def cpu_model
    `grep "model name" /proc/cpuinfo | sed -e 's/^.*: //' | head -n 1`.strip
  end

  def core_count
    `grep processor /proc/cpuinfo | wc -l`.strip
  end

  def cpu_ram_amount
    `grep -i memtotal /proc/meminfo | sed -e 's/MemTotal:[ ]*//' | sed -e 's/ kB//'`.strip
  end

  def main_device(src)
    `df -h #{src} | tail -1 | sed -e 's/ .*$//'`.strip
  end

  def get_filesystem(file)
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

#  def cpu_idle()
#    `mpstat 1 1 | tail -1 | awk 'NF>1{print $NF}' | sed -e 's/\\.[0-9]*$//'`.strip.to_i
#  end

#  def io_idle()
#    `mpstat | head -4 | tail -1 | awk 'NF>1{print $NF}' | sed -e 's/\\.[0-9]*$//'`.strip.to_i
#  end

def get_filesystem_block_size(main_dev, filesystem)
  "NA" if main_dev.nil? || %w[tmpfs ramfs nfs NA].include?(filesystem)

  case filesystem
  when "ext2", "ext3", "ext4"
    `sudo tune2fs -l #{main_dev} | grep -i "block size" | awk '{print $3}'`.strip
  when "xfs"
    `xfs_info #{main_dev} | grep bsize | grep data | sed -e 's/^.*bsize=//' | awk '{print $1}'`.strip
  when "vboxsf"
    "NA"
  else
    "error: unsupported filesystem #{filesystem}"
  end
end

def get_filesystem_mount_options(main_dev)
  `cat /proc/mounts | grep "#{main_dev}" | awk '{print $4}'`.strip
end

# This one is benchmark-specific, for FIO, and should be moved to its own class
def get_units(value)
  case value
  when /k/
    (value.gsub('k', '').to_i * 1024).to_s
  when /M/
    (value.gsub('M', '').to_i * 1024 * 1024).to_s
  when /G/
    (value.gsub('G', '').to_i * 1024 * 1024 * 1024).to_s
  when /T/
    (value.gsub('T', '').to_i * 1024 * 1024 * 1024 * 1024).to_s
  when /P/
    (value.gsub('P', '').to_i * 1024 * 1024 * 1024 * 1024 * 1024).to_s
  else
    value.to_s
  end
end

def switch_scheduler(dev, filesystem, scheduler, raid_members, aggregated)
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

def check_device(src)
  raise "Incorrect path or not a regular file '#{src}'" unless File.file?(src)

  # Get the mount point, filesystem, and device where the file resides
  mount_point = run_sudo("df --output=target #{src} | tail -1")
  filesystem = run_sudo("df --output=fstype #{src} | tail -1")
  device = run_sudo("df --output=source #{src} | tail -1")
  type = ""
  members = ""

  # Detect if the device is LVM or RAID
  if device.include?("/dev/mapper")
    # For LVM, use pvs to find the underlying physical volumes
    type = "LVM"
    vg_name = run_sudo("lvdisplay #{device} | grep 'VG Name' | awk '{print $3}'")
    physical_volumes = run_sudo("pvs --noheadings -o pv_name --select vg_name=#{vg_name}")
    members = physical_volumes
    aggregated = true
  elsif device.include?("/dev/md")
    # For RAID, use mdadm to get the underlying devices
    type = "RAID"
    raid_devices = run_sudo("mdadm --detail #{device} | grep '/dev/' | awk '{print $7}'")
    members = raid_devices
    aggregated = true
  else
    # For regular block devices, just show the device
    type = "physical device"
    aggregated = false
  end
  { filesystem: "#{filesystem}", type: "#{type}", members: "#{members}", aggregated: aggregated }
end

def check_raid(main_dev_name)
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

def get_cpu_consumption
  `echo "scale=3;(100 - $(mpstat | tail -n 1 | awk '{print $12}'))/100" | bc`.strip
end

def get_storage_consumption(device, main_dev)
  if device == "RAM"
    -1
  elsif device == "NFS"
    `nfsiostat | head -5 | tail -1 | awk '{print $1}'`.strip
  else
    `iostat #{main_dev} | grep #{File.basename(main_dev)} | awk '{print $2}'`.strip
  end
end



#end

