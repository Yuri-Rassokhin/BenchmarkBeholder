
class Dd < Collector

def launch(config)

def extract(raw)

  error = `echo "#{raw}" | grep error`.strip
  bandwidth = `echo "#{raw}" | grep copied | sed -e 's/^.*,//' | awk '{print $1}'`.strip.to_f
  units = `echo "#{raw}" | grep copied | sed -e 's/^.*,//' | awk '{print $2}'`.strip

  case units
  when "kB/s"
    bandwidth = bandwidth / 1024 / 1024
  when "MB/s"
    bandwidth = bandwidth / 1024
  when "GB/s"
    bandwidth = bandwidth
  when "TB/s"
    bandwidth = bandwidth * 1024
  else
    error += " failed to convert units"
  end

  {
      error: error,
      bandwidth: bandwidth
  }
end

def push(config, output, iterators)
  mysql = Mysql2::Client.new(default_file: '~/.my.cnf')

#      consumption_cpu = '#{cpu_consumption}',
#      consumption_storage_tps = '#{storage_tps}',

  query = <<-SQL
    insert into bbh.#{config[:series_benchmark]} set
      collect_bandwidth = '#{output[:bandwidth]}',
      collect_error = '\"#{output[:error]}\"',
      project_description = '\"#{config[:project_description]}\"',
      project_code = '\"#{config[:project_code]}\"',
      project_tier = '\"#{config[:project_tier]}\"',
      series_id = '#{config[:series]}',
      series_description = '\"#{config[:series_description]}\"',
      series_benchmark = '#{config[:benchmark]}',
      series_owner_name = '#{config[:series_owner_name]}',
      series_owner_email = '#{config[:series_owner_email]}',
      startup_executable = '#{config[:executable]}',
      startup_command = '#{iterators[:command]}',
      iterate_scheduler = '#{iterators[:scheduler]}',
      iterate_iteration = '#{iterators[:iteration]}',
      iterate_operation = '#{iterators[:operation]}',
      infra_host = '#{config[:host]}',
      infra_shape = '#{config[:shape]}',
      infra_filesystem = '#{config[:filesystem]}', 
      infra_filesystem_block_size = '#{config[:fs_block_size]}',
      infra_filesystem_mount_options = '\"#{config[:fs_mount_options]}\"',
      infra_storage = '#{config[:storage_type]}',
      infra_device = '#{config[:device]}',
      infra_drives = '#{config[:raid_members_amount]}',
      infra_architecture = '\"#{config[:arch]}\"',
      infra_os = '\"#{config[:release]}\"',
      infra_kernel = '\"#{config[:kernel]}\"',
      infra_cpu = '\"#{config[:cpu]}\"',
      infra_cores = #{config[:cores]},
      infra_ram = #{config[:ram]}
  SQL

  mysql.query(query)
end

  require 'open3'
  require 'mysql2'

  total_invocations = config[:iteratable_size]
  media = config[:startup_media]
  executable = config[:startup_executable]

  # Define parameter space, a Cartesian of those parameters we want to iterate over
  dimensions = [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_schedulers],
    config[:iterate_sizes],
    config[:iterate_operations]
  ]

  # Main loop: iterate over parameter space
  dimensions.inject(&:product).map(&:flatten).each do |iteration, scheduler, size, operation|
    #switch_scheduler $scheduler
    case operation
    when "read"
      flow = "if=#{config[:startup_media]} of=/dev/null"
    when "write"
      flow = "if=/dev/zero of=#{config[:startup_media]}"
    end
    command = "#{executable} #{flow} bs=#{size} count=1"
    #puts command
    # Commonly used: run the prepared command and capture its output
    stdout, stderr, status = Open3.capture3("#{command}")
    output = extract(stderr)
    push(config, output, {iteration: iteration, scheduler: scheduler, size: size, operation: operation, command: command})
    end
end

end
