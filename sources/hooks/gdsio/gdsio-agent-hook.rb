#!/usr/bin/env ruby

require 'open3'

# Get NVIDIA driver and CUDA versions
nvidia_driver_version = `nvidia-smi | grep NVIDIA-SMI | awk '{print $6}'`.strip
nvidia_cuda_version = `nvidia-smi | grep NVIDIA-SMI | awk '{print $9}'`.strip

def push_sql(
  series:, desc:, host:, shape:, filesystem:, storage_type:, raid_members_amount:, operation:, jobs:, gpu_mode:, block_size:, scheduler:, iops:, bw:, lat:,
  gpu_consumptions:, gpu_ram_consumptions:, gpu_ram_per_device:, cpu_consumption:, storage_tps:, iteration:, arch:, release:, kernel:, cpu:, cores:, ram:, 
  benchmark:, line:, device:, error_content:, operations:, gpu_modes:, block_sizes:, jobs_from:, jobs_to:, increment:, schedulers:, hosts:, project_description:, 
  series_owner_name:, series_owner_email:, project_code:, project_tier:, debug_scheduler:, debug_ops:, duration:, fs_block_size:, nvidia_cuda_version:, nvidia_driver_version:, fs_mount_options:, sql_log_file:
)
  sql = <<~SQL
    insert into BENCHMARKING.gdsio values(
      '#{series}', '#{desc}', '#{host}', '#{shape}', '#{filesystem}', '#{storage_type}', '#{raid_members_amount}', '#{operation}', '#{jobs}', '#{gpu_mode}', '#{block_size}',
      '#{scheduler}', '#{iops}', '#{bw}', '#{lat}', '#{gpu_consumptions[0]}', '#{gpu_consumptions[1]}', '#{gpu_consumptions[2]}', '#{gpu_consumptions[3]}', '#{gpu_consumptions[4]}',
      '#{gpu_consumptions[5]}', '#{gpu_consumptions[6]}', '#{gpu_consumptions[7]}', '#{gpu_ram_consumptions[0]}', '#{gpu_ram_consumptions[1]}', '#{gpu_ram_consumptions[2]}', 
      '#{gpu_ram_consumptions[3]}', '#{gpu_ram_consumptions[4]}', '#{gpu_ram_consumptions[5]}', '#{gpu_ram_consumptions[6]}', '#{gpu_ram_consumptions[7]}', '#{gpu_ram_per_device}', 
      '#{cpu_consumption}', '#{storage_tps}', '#{iteration}', '#{arch}', '#{release}', '#{kernel}', '#{cpu}', '#{cores}', '#{ram}', '#{benchmark}', '#{line}', '#{device}', 
      '#{error_content}', '#{operations}', '#{gpu_modes}', '#{block_sizes}', '#{jobs_from}', '#{jobs_to}', '#{increment}', '#{schedulers}', '#{hosts}', '#{project_description}', 
      '#{series_owner_name}', '#{series_owner_email}', '#{project_code}', '#{project_tier}', '#{debug_scheduler}', '#{debug_ops}', '#{duration}', '#{fs_block_size}', 
      '#{nvidia_cuda_version}', '#{nvidia_driver_version}', '#{fs_mount_options}'
    )
  SQL

  Open3.capture2("mysql -e \"#{sql}\" BENCHMARKING &>>#{sql_log_file}")
end

def get_eta(total_time, run, duration)
  minutes = (total_time - run * duration) / 60
  if minutes > 1440
    "#{minutes / 1440}d #{(minutes % 1440) / 60}h"
  elsif minutes > 59
    "#{minutes / 60}h #{minutes % 60}m"
  else
    "#{minutes}min"
  end
end

def get_actor(path, benchmark)
  path.empty? ? benchmark : "#{path}/#{benchmark}"
end

total_runs = ENV['OPERATIONS'].split.size * ENV['SCHEDULERS'].split.size * ENV['GPU_MODES'].split.size * ENV['BLOCK_SIZES'].split.size * ((ENV['JOBS_TO'].to_i - ENV['JOBS_FROM'].to_i) / ENV['INCREMENT'].to_i + 1) * ENV['ITERATIONS'].to_i
total_time = total_runs / 2
error_counter = 0
run = 1
iteration = 1
scheduler = ""
line = ""
operation = ""
jobs = 0
output_file = Tempfile.new('output')
error_file = Tempfile.new('error')
benchmark_log_file = Tempfile.new('benchmark_log')
sql_log_file = Tempfile.new('sql_log')

path = ENV['PATH']
src = ENV['SRC']
desc = ENV['DESC']
host = ENV['HOST']
shape = ENV['SHAPE']
filesystem = ENV['FILESYSTEM']
storage_type = ENV['STORAGE_TYPE']
raid_members_amount = ENV['RAID_MEMBERS_AMOUNT']
arch = ENV['ARCH']
release = ENV['RELEASE']
kernel = ENV['KERNEL']
cpu = ENV['CPU']
cores = ENV['CORES']
ram = ENV['RAM']
benchmark = ENV['BENCHMARK']
device = ENV['DEVICE']
project_description = ENV['PROJECT_DESCRIPTION']
series_owner_name = ENV['SERIES_OWNER_NAME']
series_owner_email = ENV['SERIES_OWNER_EMAIL']
project_code = ENV['PROJECT_CODE']
project_tier = ENV['PROJECT_TIER']
fs_block_size = ENV['FS_BLOCK_SIZE']
duration = ENV['DURATION']
operations = ENV['OPERATIONS']
gpu_modes = ENV['GPU_MODES']
block_sizes = ENV['BLOCK_SIZES']
jobs_from = ENV['JOBS_FROM']
jobs_to = ENV['JOBS_TO']
increment = ENV['INCREMENT']
schedulers = ENV['SCHEDULERS']
hosts = ENV['HOSTS']

actor = get_actor(path, benchmark)

while iteration <= ENV['ITERATIONS'].to_i
  operations.split.each do |operation|
    gpu_modes.split.each do |gpu_mode|
      schedulers.split.each do |scheduler|
        block_sizes.split.each do |block_size|
          jobs = jobs_from.to_i
          while jobs <= jobs_to.to_i
            # Replace switch_scheduler function with appropriate Ruby logic if needed
            line = "#{actor} -f #{src} -d 0 -w #{jobs} -s 1G -x #{gpu_mode} -i #{block_size} -I #{operation} -T #{duration}"
            percentage = run * 100 / total_runs
            eta = get_eta(total_time, run, duration)
            puts "NODE #{host} | SERIES #{series} | TIER #{project_tier} | RUN #{run}/#{total_runs} | DONE #{percentage}% | ETA=#{eta} | CONF=#{conf_file}"
            output, status = Open3.capture2(line)
            output_file.write(output)
            benchmark_log_file.write(output)

            gpu_consumptions = (0..7).map { |i| `gpustat --no-header | head -n #{i + 1} | tail -1 | awk '{print $6}'`.strip }
            gpu_ram_consumptions = (0..7).map { |i| `gpustat --no-header | head -n #{i + 1} | tail -1 | awk '{print $9}'`.strip }
            gpu_ram_per_device = `gpustat --no-header | head -n 1 | awk '{print $11}'`.strip

            cpu_consumption = `echo "scale=3;(100 - $(mpstat | tail -n 1 | awk '{print $12}'))/100" | bc`.strip
            storage_tps = `iostat #{device} | grep #{File.basename(device)} | awk '{print $2}'`.strip

            if File.size(error_file.path) > 0
              warning("iteration drops an error: #{File.read(error_file.path)}")
              error_counter += 1
            end

            push_sql(
              series: series, desc: desc, host: host, shape: shape, filesystem: filesystem, storage_type: storage_type, raid_members_amount: raid_members_amount,
              operation: operation, jobs: jobs, gpu_mode: gpu_mode, block_size: block_size, scheduler: scheduler, iops: iops, bw: bw, lat: lat,
              gpu_consumptions: gpu_consumptions, gpu_ram_consumptions: gpu_ram_consumptions, gpu_ram_per_device: gpu_ram_per_device, cpu_consumption: cpu_consumption,
              storage_tps: storage_tps, iteration: iteration, arch: arch, release: release, kernel: kernel, cpu: cpu, cores: cores, ram: ram, benchmark: benchmark,
              line: line, device: device, error_content: File.read(error_file.path), operations: operations, gpu_modes: gpu_modes, block_sizes: block_sizes,
              jobs_from: jobs_from, jobs_to: jobs_to, increment: increment, schedulers: schedulers, hosts: hosts, project_description: project_description,
              series_owner_name: series_owner_name, series_owner_email: series_owner_email, project_code: project_code, project_tier: project_tier,
              debug_scheduler: debug_scheduler, debug_ops: debug_ops, duration: duration, fs_block_size: fs_block_size, nvidia_cuda_version: nvidia_cuda_version,
              nvidia_driver_version: nvidia_driver_version, fs_mount_options: fs_mount_options, sql_log_file: sql_log_file
            )
            run += 1
            jobs += increment.to_i
          end
        end
      end
    end
  end
  iteration += 1
end

output_file.close
error_file.close
benchmark_log_file.close
sql_log_file.close


