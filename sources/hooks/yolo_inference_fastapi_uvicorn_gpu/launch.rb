
class Object_storage_coco_reading < Collector

def launch(config)

def push(config, output, iterators)
  mysql = Mysql2::Client.new(default_file: '~/.my.cnf')

#      consumption_cpu = '#{cpu_consumption}',
#      consumption_storage_tps = '#{storage_tps}',

# NOTE: workload-specific customizations: collect_bandwidth
  query = <<-SQL
    insert into #{config[:series_benchmark]} set
      collect_bandwidth = '#{output[:bandwidth]}',
      collect_error = '\"#{output[:error]}\"',
      collect_time = '#{output[:time]}',
      collect_size = '#{output[:size]}',
      project_description = '\"#{config[:project_description]}\"',
      project_code = '\"#{config[:project_code]}\"',
      project_tier = '\"#{config[:project_tier]}\"',
      series_id = '#{config[:series]}',
      series_description = '\"#{config[:series_description]}\"',
      series_benchmark = '#{config[:series_benchmark]}',
      series_owner_name = '#{config[:series_owner_name]}',
      series_owner_email = '#{config[:series_owner_email]}',
      startup_actor = '#{config[:startup_actor]}',
      startup_command = '\"#{iterators[:command]}\"',
      iterate_scheduler = '#{iterators[:scheduler]}',
      iterate_iteration = '#{iterators[:iteration]}',
      iterate_operation = '#{iterators[:operation]}',
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
      infra_ram = '#{config[:ram]}'
  SQL
  mysql.query(query)
end

  require 'open3'
  require 'mysql2'

  # NOTE: adding workload-specific modules
  require 'oci'
  require 'pathname'

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]

  # NOTE: adding workload-specific initialization of the target
  target_initialize()

  # Define parameter space, a Cartesian of those parameters we want to iterate over
  dimensions = [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_processes].to_a,
    config[:iterate_requests].to_a
  ]

  language = "bash"
  # NOTE: loop is a template, workload-specific iterators inherited from the 'dimensions' variable
  dimensions.inject(&:product).map(&:flatten).each do |iteration, processes, requests|

    # launch the target: uvicorn+fastapi inference server
    target = spawn("uvicorn yolo_fastapi_binary_inference_server:app --host 0.0.0.0 --port 5000 --workers #{iterate_processes} --log-level critical --no-access-log", out: "/dev/null", err: "/dev/null")
    Process.detach(target)
    sleep(5)

    # execute the benchmark and capture its raw output
    command = "ab -n 3000 -c 300 -p post_data.txt -T "application/octet-stream" http://localhost:5000/predict/ 2>&1 | grep "Requests per second" | awk '{print $4}'"
    raw_result = `ab -n 3000 -c 300 -p post_data.txt -T "application/octet-stream" http://localhost:5000/predict/ 2>&1`

    # kill the inference server
    Process.kill("TERM", target)

    # extract benchmark results
    inference_time = `echo #{raw_result} | grep "Requests per second" | awk '{print $4}'`
    error_count = `echo #{raw_result} | grep "Failed requests" | awk '{print $3}'`
    error = ( error_count == "0" ? "" : error_count )

    # push benchmark results to the database
    output = { inference_time: inference_time, error: error }
    iterators = { iteration: iteration, processes: processes, requests: requests, scheduler: "NA" }
    push(config, output, iterators, {command: command.gsub("'", "''"), language: language})
    end
  end
end

end
