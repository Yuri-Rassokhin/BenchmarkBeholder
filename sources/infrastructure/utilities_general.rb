
require 'open3'
require 'fileutils'
require 'tempfile'

module UtilitiesGeneral

  def args_show(args)
    puts args
  end

#  def out(status, output)
#    puts "[ " + status.to_s + ", #{output} ]"
#  end

  def file_exists?(file)
    `test -f #{file} && echo 1`.strip == "1"
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

  def get_filesystem(src)
    s_type = `stat -c "%F" #{src}`.strip
    case s_type
    when "regular file", "regular empty file"
      `df -T #{src} | tail -1 | awk '{print $2}'`.strip
    when "block special device"
      "N/A"
    else
#      "incorrect type of test target #{src}: #{s_type}" 
      nil
    end
  end

  def cpu_idle()
    `mpstat 1 1 | tail -1 | awk 'NF>1{print $NF}' | sed -e 's/\\.[0-9]*$//'`.strip
  end

  def io_idle()
    `mpstat | head -4 | tail -1 | awk 'NF>1{print $NF}' | sed -e 's/\\.[0-9]*$//'`.strip
  end

def get_filesystem_block_size(main_dev, filesystem)
  nil if main_dev.nil? || %w[tmpfs ramfs nfs].include?(filesystem)

  case filesystem
  when "ext2", "ext3", "ext4"
    `sudo tune2fs -l #{main_dev} | grep -i "block size" | awk '{print $3}'`.strip
  when "xfs"
    `xfs_info #{main_dev} | grep bsize | grep data | sed -e 's/^.*bsize=//' | awk '{print $1}'`.strip
  when "vboxsf"
    "n/a"
  else
    "error: unsupported filesystem '#{filesystem}'"
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

def switch_scheduler(main_dev_name, filesystem, scheduler, raid_members)
  return if %w[ramfs tmpfs nfs fuse.glusterfs].include?(filesystem) || scheduler == "N/A"

  if raid_members.empty?
    return unless File.exist?("/sys/block/#{main_dev_name}/queue/scheduler")
    `sudo bash -c "echo #{scheduler} > /sys/block/#{main_dev_name}/queue/scheduler"`
    `cat /sys/block/#{main_dev_name}/queue/scheduler`.strip
  else
    raid_members.each do |drive|
      if drive.include?("nvme") && `cat /sys/module/nvme_core/parameters/multipath`.strip == "Y"
        drive = drive.gsub(/(\d)/, 'c\1')
      end
      `sudo bash -c "echo #{scheduler} > /sys/block/#{drive}/queue/scheduler"`
      `cat /sys/block/#{drive}/queue/scheduler on #{drive}`
    end.join(" ")
  end
end

def check_raid(main_dev_name)
  raid_level = `grep #{main_dev_name} /proc/mdstat | tr ' ' '\n' | grep raid | sed -e 's/raid//'`.strip
  if raid_level.empty?
    { raid_members: "", raid_members_amount: 1, storage_type: "\"Single Drive\"" }
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



end

