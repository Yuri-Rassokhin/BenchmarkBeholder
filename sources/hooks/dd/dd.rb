
class Dd < Collector

def initialize(config, url, mode, logger, series)
  super(config, url, mode, logger, series)
end

def push(config)
# Explanation
# Configuration Hash: The config hash contains all the variables that were previously set as environment variables in the Bash script.
# MySQL Client Setup: The Mysql2::Client.new initializes a connection to the MySQL database.
# Query Preparation: The SQL query is prepared using string interpolation to insert the values from the config hash.
# Execute Query: The client.query(query) method executes the SQL query.
# Example Usage: The config hash is populated with sample data, and the load_series_data function is called to demonstrate how it works.

  # Unpack configuration variables
  error_file = config[:error_file]
  series = config[:series]
  desc = config[:desc]
  shape = config[:shape]
  scheduler = config[:scheduler]
  filesystem = config[:filesystem]
  fs_block_size = config[:fs_block_size]
  fs_mount_options = config[:fs_mount_options]
  storage_type = config[:storage_type]
  raid_members_amount = config[:raid_members_amount]
  device = config[:device]
  gpu_consumption = config[:gpu_consumption]
  gpu_ram_consumption = config[:gpu_ram_consumption]
  gpu_ram_per_device = config[:gpu_ram_per_device]
  cpu_consumption = config[:cpu_consumption]
  storage_tps = config[:storage_tps]
  arch = config[:arch]
  release = config[:release]
  kernel = config[:kernel]
  cpu = config[:cpu]
  cores = config[:cores]
  ram = config[:ram]
  nvidia_cuda_version = config[:nvidia_cuda_version]
  nvidia_driver_version = config[:nvidia_driver_version]
  benchmark = config[:benchmark]
  line = config[:line]
  error = config[:error]
  iteration = config[:iteration]
  schedulers = config[:schedulers]
  hosts = config[:hosts]
  project_description = config[:project_description]
  project_code = config[:project_code]
  project_tier = config[:project_tier]
  series_owner_name = config[:series_owner_name]
  series_owner_email = config[:series_owner_email]
  debug_scheduler = config[:debug_scheduler]
  host = config[:host]
  eta_minutes = config[:eta_minutes]
  iter = config[:iter]
  total_loss = config[:total_loss]
  loss_cls = config[:loss_cls]
  loss_box_reg = config[:loss_box_reg]
  loss_mask = config[:loss_mask]
  loss_rpn_cls = config[:loss_rpn_cls]
  loss_rpn_loc = config[:loss_rpn_loc]
  timing = config[:timing]
  last_timing = config[:last_timing]
  data_timing = config[:data_timing]
  last_data_timing = config[:last_data_timing]
  lr = config[:lr]
  max_mem = config[:max_mem]
  real_time = config[:real_time]
  real_time_human = config[:real_time_human]
  number_of_gpus = config[:number_of_gpus]
  gds_supported = config[:gds_supported]
  chunk = config[:chunk]

  # Check if error file exists and is not empty
  if !File.exist?(error_file) || File.size(error_file).zero?
    # TODO: handle empty or non-existent error file
  end

  # Create a MySQL client
  client = Mysql2::Client.new(
    host: "your_mysql_host",
    username: "your_mysql_username",
    password: "your_mysql_password",
    database: "BENCHMARKING"
  )

  # Prepare the query
  query = <<-SQL
    INSERT INTO BENCHMARKING.detectron2_training SET
      series_id = '#{series}',
      series_description = '\"#{desc}\"',
      shape = '#{shape}',
      storage_scheduler = '#{scheduler}',
      storage_filesystem = '#{filesystem}',
      storage_filesystem_block_size = '#{fs_block_size}',
      storage_filesystem_mount_options = '\"#{fs_mount_options}\"',
      storage_type = '#{storage_type}',
      storage_drives = '#{raid_members_amount}',
      storage_device = '#{device}',
      consumption_gpu0 = '#{gpu_consumption[0]}',
      consumption_gpu1 = '#{gpu_consumption[1]}',
      consumption_gpu2 = '#{gpu_consumption[2]}',
      consumption_gpu3 = '#{gpu_consumption[3]}',
      consumption_gpu4 = '#{gpu_consumption[4]}',
      consumption_gpu5 = '#{gpu_consumption[5]}',
      consumption_gpu6 = '#{gpu_consumption[6]}',
      consumption_gpu7 = '#{gpu_consumption[7]}',
      consumption_ram_gpu0 = '#{gpu_ram_consumption[0]}',
      consumption_ram_gpu1 = '#{gpu_ram_consumption[1]}',
      consumption_ram_gpu2 = '#{gpu_ram_consumption[2]}',
      consumption_ram_gpu3 = '#{gpu_ram_consumption[3]}',
      consumption_ram_gpu4 = '#{gpu_ram_consumption[4]}',
      consumption_ram_gpu5 = '#{gpu_ram_consumption[5]}',
      consumption_ram_gpu6 = '#{gpu_ram_consumption[6]}',
      consumption_ram_gpu7 = '#{gpu_ram_consumption[7]}',
      consumption_ram_per_gpu = '#{gpu_ram_per_device}',
      consumption_cpu = '#{cpu_consumption}',
      consumption_storage_tps = '#{storage_tps}',
      infra_arch = '#{arch}',
      infra_osrelease = '#{release}',
      infra_oskernel = '#{kernel}',
      infra_oscpu = '#{cpu}',
      infra_cores = #{cores},
      infra_ram = #{ram},
      infra_cuda_version = '#{nvidia_cuda_version}',
      infra_cuda_driver_version = '#{nvidia_driver_version}',
      benchmark = '#{benchmark}',
      invocation_command = '#{line}',
      invocation_error = '#{File.read(error) if File.exist?(error)}',
      invocation_iteration = '#{iteration}',
      config_schedulers = '#{schedulers}',
      config_hosts = '#{hosts}',
      project_description = '\"#{project_description}\"',
      project_code = '\"#{project_code}\"',
      project_tier = '\"#{project_tier}\"',
      owner_name = '#{series_owner_name}',
      owner_email = '#{series_owner_email}',
      debug_scheduler = '\"#{debug_scheduler}\"',
      debug_host = '#{host}',
      app_eta = '#{eta_minutes}',
      app_iter = '#{iter}',
      app_total_loss = '#{total_loss}',
      app_loss_cls = '#{loss_cls}',
      app_loss_box_reg = '#{loss_box_reg}',
      app_loss_mask = '#{loss_mask}',
      app_loss_rpn_cls = '#{loss_rpn_cls}',
      app_loss_rpn_loc = '#{loss_rpn_loc}',
      app_time = '#{timing}',
      app_last_time = '#{last_timing}',
      app_data_time = '#{data_timing}',
      app_last_data_time = '#{last_data_timing}',
      app_lr = '#{lr}',
      app_max_mem = '#{max_mem}',
      real_time_passed_sec = '#{real_time}',
      real_time_passed = '\"#{real_time_human}\"',
      app_gpu_quantity = '#{number_of_gpus}',
      infra_gds_enabled = '\"#{gds_supported}\"',
      log = '\"#{chunk}\"';
  SQL

  # Execute the query
  client.query(query)

  puts "Data inserted successfully."
end

require_relative 'launch'

def get_dynamic_metrics
  get_gpu_consumption
  get_cpu_consumption
  get_storage_consumption
end

private

# analyze and process an incoming line from the benchmark
def process(line)
  items = extract(line)

  if items[:eta] == ""
    items[:eta] == "TBD"
    return items
  end

  get_dynamic_metrics
  push
  @logger.info("node #{@host} | series #{@series} | tier #{@project_tier} | run #{@invocation}/#{@total_invocations} | eta #{@eta_msg}")
end

# return a map of data elements extracted from line
def extract(line)
  {
    eta: log_line[/eta: ([\d:]+)/, 1],
    iter: log_line[/iter: (\d+)/, 1],
    total_loss: log_line[/total_loss: ([\d.]+)/, 1],
    loss_cls: log_line[/loss_cls: ([\d.]+)/, 1],
    loss_box_reg: log_line[/loss_box_reg: ([\d.]+)/, 1],
    loss_mask: log_line[/loss_mask: ([\d.]+)/, 1],
    loss_rpn_cls: log_line[/loss_rpn_cls: ([\d.]+)/, 1],
    loss_rpn_loc: log_line[/loss_rpn_loc: ([\d.]+)/, 1],
    timing: log_line[/time: ([\d.]+)/, 1],
    last_timing: log_line[/last_time: ([\d.]+)/, 1],
    data_timing: log_line[/data_time: ([\d.]+)/, 1],
    last_data_timing: log_line[/last_data_time: ([\d.]+)/, 1],
    lr: log_line[/lr: ([\d.]+)/, 1],
    max_mem: log_line[/max_mem: (\d+)/, 1]
  }
end

def get_real_time(current_time, start_time)
  real_time = current_time - end_time
  hh = real_time / 3600
  mm = (real_time % 3600) / 60
  real_time_human = "#{hh}h #{mm}min"
  return real_time_human
end

def format_eta_to_minutes(eta)
  # Split the time string into hours, minutes, and seconds
  time_parts = eta.split(':').map(&:to_i)
  hh, mm, ss = time_parts

  # Calculate the total minutes
  eta_minutes = hh * 60 + mm

  # If seconds are 30 or more, add 1 to the minutes
  eta_minutes += 1 if ss >= 30

  eta_minutes
end


end

