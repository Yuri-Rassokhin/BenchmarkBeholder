
# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimensions(config)
  [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_processes].to_a,
    config[:iterate_requests].to_a
  ]
end

# CUSTOMIZE: give names to the dimensions, as a comma-separated list
def dimension_naming
  [ :iteration, :processes, :requests, ]
end

# CUSTOMIZE: if you need one-time intitialization before traversal of the pararameter space started, it's here
def prepare(config = nil)
  require 'net/http'
  require 'json'
  require 'thread'
  require 'method_source'
  require 'pathname'

  Process.setrlimit(:NOFILE, 65535)
  Process.setrlimit(Process::RLIMIT_NOFILE, 65535)
end

def invocation(config, iterator)

  # execute the benchmark and capture its raw output

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]
  processes = iterator[:processes]
  requests = iterator[:requests]
  language = "bash"
  app = config[:startup_target_application]
  app = app.end_with?('.py') ? app.chomp('.py') : app
  app_dir = File.dirname(app)
  app_name = File.basename(app)

  reader, writer = IO.pipe
  # launch the target: uvicorn+fastapi inference server
  target = spawn("uvicorn #{app_name}:app --app-dir #{app_dir} --host 0.0.0.0 --port 5000 --workers #{processes} --reload", out: writer, err: writer)
  writer.close
  Process.detach(target)
  sleep(10)

    # execute the benchmark and capture its raw output
    command = "ab -n #{requests*10} -c #{requests} -p #{app_dir}/post_data.txt -T \"application/octet-stream\" http://localhost:5000/predict/ 2>&1"
    raw_result = `#{command}`

    server_raw_output = reader.read

    # kill the inference server
    Process.kill("TERM", target) rescue nil # TODO: check if previous isntance is dead

    # extract benchmark results
    inference_time = `echo "#{raw_result}" | grep "Requests per second" | awk '{print $4}'`
    request_error_count = `echo "#{raw_result}" | grep "Failed requests" | awk '{print $3}'`
    failed_requests = ( request_error_count == 0 ? "" : request_error_count )
    puts failed_requests

    cuda_error = `echo "#{server_raw_output}" | grep "CUDA run out of memory"`[0..499]
    response_error = `echo "#{server_raw_output}" | grep -i "error | grep -vi dictionary"`[0..499]

    # collect result
    collect = { inference_time: inference_time, failed_requests: failed_requests, cuda_error: cuda_error, response_error: response_error }
    iterate = { iteration: iterator[:iteration], processes: processes, requests: requests }
    startup = { command: command.gsub("'", "''"), language: "ruby" }

    return { startup: startup, iterate: iterate, collect: collect }
  end

