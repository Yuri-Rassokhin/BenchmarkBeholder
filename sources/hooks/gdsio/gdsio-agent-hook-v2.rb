#!/usr/bin/env ruby

require 'open3'
require 'tempfile'

# Helper Functions
def run_command(cmd)
  Open3.capture2(cmd).first.strip
end

def push_sql(params)
  sql = <<~SQL
    INSERT INTO BENCHMARKING.gdsio VALUES (
      '#{params[:series]}', '#{params[:desc]}', '#{params[:host]}', '#{params[:shape]}', '#{params[:filesystem]}', 
      '#{params[:storage_type]}', '#{params[:raid_members_amount]}', '#{params[:operation]} (#{params[:operation_desc]})', 
      '#{params[:jobs]}', '#{params[:gpu_mode]} (#{params[:gpu_mode_desc]})', '#{params[:block_size]}', '#{params[:scheduler]}', 
      '#{params[:iops]}', '#{params[:bw]}', '#{params[:lat]}', '#{params[:gpu_consumptions].join("','")}', 
      '#{params[:gpu_ram_consumptions].join("','")}', '#{params[:gpu_ram_per_device]}', '#{params[:cpu_consumption]}', 
      '#{params[:storage_tps]}', '#{params[:iteration]}', '#{params[:arch]}', '#{params[:release]}', '#{params[:kernel]}', 
      '#{params[:cpu]}', '#{params[:cores]}', '#{params[:ram]}', '#{params[:benchmark]}', '#{params[:line]}', '#{params[:device]}', 
      '#{params[:error_content]}', '#{params[:operations]}', '#{params[:gpu_modes]}', '#{params[:block_sizes]}', 
      '#{params[:jobs_from]}', '#{params[:jobs_to]}', '#{params[:increment]}', '#{params[:schedulers]}', '#{params[:hosts]}', 
      '#{params[:project_description]}', '#{params[:series_owner_name]}', '#{params[:series_owner_email]}', '#{params[:project_code]}', 
      '#{params[:project_tier]}', '#{params[:debug_scheduler]}', '#{params[:debug_ops]}', '#{params[:duration]}', '#{params[:fs_block_size]}', 
      '#{params[:nvidia_cuda_version]}', '#{params[:nvidia_driver_version]}', '#{params[:fs_mount_options]}'
    )
  SQL
  run_command("mysql -e \"#{sql}\" BENCHMARKING &>>#{params[:sql_log_file]}")
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

def get_executable(path, benchmark)
  path.empty? ? benchmark : "#{path}/#{benchmark}"
end

# Initialization
nvidia_driver_version = run_command("nvidia-smi | grep NVIDIA-SMI | awk '{print $6}'")
nvidia_cuda_version = run_command("nvidia-smi | grep NVIDIA-SMI | awk '{print $9}'")

output_file = Tempfile.new('output')
error_file = Tempfile.new('error')
benchmark_log_file = Tempfile.new('benchmark_log')
sql_log_file = Tempfile.new('sql_log')

config = {
  series: ENV['SERIES'],
  desc: ENV['DESC'],
  host: ENV['HOST'],
  shape: ENV['SHAPE'],
  filesystem: ENV['FILESYSTEM'],
  storage_type: ENV['STORAGE_TYPE'],
  raid_members_amount: ENV['RAID_MEMBERS_AMOUNT'],
  arch: ENV['ARCH'],
  release: ENV['RELEASE'],
  kernel: ENV['KERNEL'],
  cpu: ENV['CPU'],
  cores: ENV['CORES'],
  ram: ENV['RAM'],
  benchmark: ENV['BENCHMARK'],
  device: ENV['DEVICE'],
  project_description: ENV['PROJECT_DESCRIPTION'],
  series_owner_name: ENV['SERIES_OWNER_NAME'],
  series_owner_email: ENV['SERIES_OWNER_EMAIL'],
  project_code: ENV['PROJECT_CODE'],
  project_tier: ENV['PROJECT_TIER'],
  fs_block_size: ENV['FS_BLOCK_SIZE'],
  duration: ENV['DURATION'],
  operations: ENV['OPERATIONS'].split,
  gpu_modes: ENV['GPU_MODES'].split,
  block_sizes: ENV['BLOCK_SIZES'].split,
  jobs_from: ENV['JOBS_FROM'].to_i,
  jobs_to: ENV['JOBS_TO'].to_i,
  increment: ENV['INCREMENT'].to_i,
  schedulers: ENV['SCHEDULERS'].split,
  hosts: ENV['HOSTS'],
  sql_log_file: sql_log_file.path,
  nvidia_cuda_version: nvidia_cuda_version,
  nvidia_driver_version: nvidia_driver_version
}

total_runs = config[:operations].size * config[:schedulers].size * config[:gpu_modes].size * config[:block_sizes].size * ((config[:jobs_to] - config[:jobs_from]) / config[:increment] + 1) * ENV['ITERATIONS'].to_i
total_time = total_runs / 2
error_counter = 0
run = 1

# Execution
executable = get_executable(ENV['PATH'], config[:benchmark])

(1..ENV['ITERATIONS'].to_i).each do |iteration|
  config[:operations].each do |operation|
    config[:gpu_modes].each do |gpu_mode|
      config[:schedulers].each do |scheduler|
        config[:block_sizes].each do |block_size|
          jobs = config[:jobs_from]
          while jobs <= config[:jobs_to]
            line = "#{executable} -f #{ENV['SRC']} -d 0 -w #{jobs} -s 1G -x #{gpu_mode} -i #{block_size} -I #{operation} -T #{config[:duration]}"
            percentage = run * 100 / total_runs
            eta = get_eta(total_time, run, config[:duration])
            puts "NODE #{config[:host]} | SERIES #{config[:series]} | TIER #{config[:project_tier]} | RUN #{run}/#{total_runs} | DONE #{percentage}% | ETA=#{eta} | CONF=#{ENV['CONF_FILE']}"

            output, status = Open3.capture2(line)
            File.write(output_file.path, output)
            File.write(benchmark_log_file.path, output)

            gpu_consumptions = (0..7).map { |i| run_command("gpustat --no-header | head -n #{i + 1} | tail -1 | awk '{print $6}'") }
            gpu_ram_consumptions = (0..7).map { |i| run_command("gpustat --no-header | head -n #{i + 1} | tail -1 | awk '{print $9}'") }
            gpu_ram_per_device = run_command("gpustat --no-header | head -n 1 | awk '{print $11}'")
            cpu_consumption = run_command("echo \"scale=3;(100 - $(mpstat | tail -n 1 | awk '{print $12}'))/100\" | bc")
            storage_tps = run_command("iostat #{config[:device]} | grep #{File.basename(config[:device])} | awk '{print $2}'")

            if File.size(error_file.path) > 0
              warning("iteration drops an error: #{File.read(error_file.path)}")
              error_counter += 1
            end

            params = config.merge(
              operation: operation,
              gpu_mode: gpu_mode,
              block_size: block_size,
              scheduler: scheduler,
              jobs: jobs,
              line: line,
              iops: (output.match(/ops: (\d+)/)[1].to_i / config[:duration].to_i rescue -1),
              bw: (output.match(/Throughput: (\d+)/)[1] rescue -1),
              lat: (output.match(/Avg_Latency: (\d+)/)[1] rescue -1),
              gpu_consumptions: gpu_consumptions,
              gpu_ram_consumptions: gpu_ram_consumptions,
              gpu_ram_per_device: gpu_ram_per_device,
              cpu_consumption: cpu_consumption,
              storage_tps: storage_tps,
              iteration: iteration,
              error_content: File.read(error_file.path),
              operation_desc: %w[sequential\ reading sequential\ writing random\ reading random\ writing][operation.to_i],
              gpu_mode_desc: %w[GPU_DIRECT CPU_ONLY CPU_GPU CPU_ASYNC_GPU CPU_CACHED_GPU GPU_DIRECT_ASYNC GPU_BATCH GPU_BATCH_STREAM][gpu_mode.to_i]
            )
            push_sql(params)

            run += 1
            jobs += config[:increment]
          end
        end
      end
    end
  end
end

output_file.close
error_file.close
benchmark_log_file.close
sql_log_file.close


