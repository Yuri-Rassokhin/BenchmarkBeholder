
class Yolo_inference_fastapi_uvicorn_gpu < Collector

def launch(config)

require 'open3'
require 'mysql2'

def cartesian(dimensions)
  # Ensure all dimensions are arrays
  normalized_dimensions = dimensions.map do |dim|
    dim.is_a?(Enumerable) ? dim.to_a : [dim]
  end

  # Remove empty dimensions
  filtered_dimensions = normalized_dimensions.reject(&:empty?)

  # Handle special case: single dimension
  if filtered_dimensions.size == 1
    return filtered_dimensions.first.to_enum unless block_given?
    return filtered_dimensions.first.each { |e| yield(e) }
  end

  # Handle multiple dimensions
  cartesian = filtered_dimensions.inject(&:product).map(&:flatten)

  # Return an enumerator if no block is given
  return cartesian.to_enum unless block_given?

  # Yield each combination if a block is given
  cartesian.each do |combination|
    yield(*combination)
  end
end

def push!(query, config)
  mysql = Mysql2::Client.new(default_file: '~/.my.cnf')
  # consumption_cpu = '#{cpu_consumption}',
  # consumption_storage_tps = '#{storage_tps}',
  generic_query = <<-SQL
      insert into #{config[:series_benchmark]} set
      project_description = '\"#{config[:project_description]}\"',
      project_code = '\"#{config[:project_code]}\"',
      project_tier = '\"#{config[:project_tier]}\"',
      series_id = '#{config[:series]}',
      series_description = '\"#{config[:series_description]}\"',
      series_benchmark = '#{config[:series_benchmark]}',
      series_owner_name = '#{config[:series_owner_name]}',
      series_owner_email = '#{config[:series_owner_email]}',
      startup_actor = '#{config[:startup_actor]}',
      infra_host = '#{config[:host]}',
      infra_shape = '#{config[:shape]}',
      infra_filesystem = '\"#{config[:filesystem]}\"', 
      infra_storage = '\"#{config[:storage_type]}\"',
      infra_device = '\"#{config[:device]}\"',
      infra_drives = '#{config[:raid_members_amount]}',
      infra_architecture = '\"#{config[:arch]}\"',
      infra_os = '\"#{config[:release]}\"',
      infra_kernel = '\"#{config[:kernel]}\"',
      infra_cpu = '\"#{config[:cpu]}\"',
      infra_cores = '#{config[:cores]}',
      infra_ram = '#{config[:ram]}',
  SQL
  mysql.query(generic_query << query << ";")
end

# CUSTOMIZE: add your "collect" and "iterate" parameters in query
def push(config, collect, iterate, startup)
  query = <<-SQL
      collect_inference_time = '#{collect[:inference_time]}',
      collect_error = '#{collect[:error]}',
      iterate_iteration = '#{iterate[:iteration]}',
      iterate_processes = '#{iterate[:processes]}',
      iterate_requests = '#{iterate[:requests]}',
      startup_command = '\"#{startup[:command]}\"',
      startup_language = '\"#{startup[:language]}\"',
  SQL
  push!(query, config)
end

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]

  # CUSTOMIZE: add the modules required for your hook
  require 'oci'
  require 'pathname'

  # CUSTOMIZE: add initialization of the variables relevant to your target
  language = "bash"
  app = config[:startup_target_application]

  # CUSTOMIZE: add your dimensions here in the form config[:my_option].to_a
  dimensions = [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_processes].to_a,
    config[:iterate_requests].to_a
  ]

  # CUSTOMIZE: add your iterator names
  cartesian(dimensions).each do |iteration, processes, requests|
    # CUSTOMIZE: add your semantics of the benchmark invocation

    # launch the target: uvicorn+fastapi inference server
    target = spawn("uvicorn #{app}:app --host 0.0.0.0 --port 5000 --workers #{processes} --log-level critical --no-access-log", out: "/dev/null", err: "/dev/null")
    Process.detach(target)
    sleep(5)

    # execute the benchmark and capture its raw output
    command = "ab -n #{requests*10} -c #{requests} -p post_data.txt -T \"application/octet-stream\" http://localhost:5000/predict/ 2>&1"
    raw_result = `#{command}`

    # kill the inference server
    Process.kill("TERM", target)

    # extract benchmark results
    inference_time = `echo "#{raw_result}" | grep "Requests per second" | awk '{print $4}'`
    error_count = `echo "#{raw_result}" | grep "Failed requests" | awk '{print $3}'`
    error = ( error_count == "0" ? "" : "#{error_count} requests failed" )

    # push benchmark results to the database
    collect = { inference_time: inference_time, error: error }
    iterate = { iteration: iteration, processes: processes, requests: requests }
    startup = { command: command.gsub("'", "''"), language: language }
    push(config, collect, iterate, startup)

  end
end

end
