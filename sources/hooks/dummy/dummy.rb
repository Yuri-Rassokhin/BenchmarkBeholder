
require 'timeout'

class Dummy < Collector

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
  cpu_consumption = config[:cpu_consumption]
  storage_tps = config[:storage_tps]
  arch = config[:arch]
  release = config[:release]
  kernel = config[:kernel]
  cpu = config[:cpu]
  cores = config[:cores]
  ram = config[:ram]
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

  # Check if error file exists and is not empty
  if !File.exist?(error_file) || File.size(error_file).zero?
    # TODO: handle empty or non-existent error file
  end

  # Create a MySQL client
  client = Mysql2::Client.new(
    host: "your_mysql_host",
    username: "your_mysql_username",
    password: "your_mysql_password",
    database: "bbh"
  )

  # Prepare the query
  query = <<-SQL
    insert into bbh.dummy set
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
      consumption_cpu = '#{cpu_consumption}',
      consumption_storage_tps = '#{storage_tps}',
      infra_arch = '#{arch}',
      infra_osrelease = '#{release}',
      infra_oskernel = '#{kernel}',
      infra_oscpu = '#{cpu}',
      infra_cores = #{cores},
      infra_ram = #{ram},
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
      log = '\"#{chunk}\"';
  SQL

  # Execute the query
  client.query(query)
end

def launch(config)
  require 'open3'

  invocation=1
  iteration=1
  scheduler=""
  iterations = config[:collect_iterations]
  total_invocations = config[:iteratable_size]

  dimensions = [
    (1..iterations).to_a,
    config[:iterate_schedulers].split(',').reject(&:empty?).to_a,
  ]

  path = config[:startup_path]

  dimensions.inject(&:product).each do |iteration, scheduler|
    #TODO: switch_scheduler $scheduler
    command = "echo This is a dummy benchmark, iteration #{iteration} with #{scheduler} IO scheduler"
    stdout, stderr, status = Open3.capture3("#{command}")
    puts stdout
  end
end

def get_dynamic_metrics
  get_cpu_consumption
  get_storage_consumption
end

private

# analyze and process an incoming line from the benchmark
def process(line)
  get_dynamic_metrics
  push
  @logger.info("node #{@host} | series #{@series} | tier #{@project_tier} | run #{@invocation}/#{@total_invocations} | eta #{@eta_msg}")

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


end
end

