
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
  [ :iteration, :processes, :requests ]
end

# CUSTOMIZE: if you need one-time intitialization before traversal of the pararameter space started, it's here
def prepare(config = nil)
  require 'net/http'
  require 'json'
  require 'thread'
  require 'method_source'
  require 'pathname'

  # set for as much scalability as possible
  Process.setrlimit(:NOFILE, 65535)
  Process.setrlimit(Process::RLIMIT_NOFILE, 65535)

  # global number of server workers, to track if it's time to reload it with another number of workers
  $workers = 0
  $device = "something"
end

def invocation(config, iterator)

  # execute the benchmark and capture its raw output

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]
  processes = iterator[:processes]
  requests = iterator[:requests]
  app = config[:startup_target_application]
  app = app.end_with?('.py') ? app.chomp('.py') : app
  app_dir = File.dirname(app)
  app_name = File.basename(app)
  model_path = config[:startup_model_path]
  scaler_path = config[:startup_scaler_path]
  target_command = ""
  device = config[:startup_device]

  reader, writer = IO.pipe
  # reload the inference server if the iterator has updated its parameters: device or workers
  if $workers != processes or $device != device
   target_array = [
      "gunicorn",
      "-k", "uvicorn.workers.UvicornWorker",
      "-w", processes.to_s,
      "-b", "0.0.0.0:8080",
      "--chdir", app_dir,
      "#{app_name}:app"
   ]
   env = { "DEVICE" => device }

   target_command = "DEVICE=#{device} MODEL_PATH=#{model_path} SCALER_PATH=#{scaler_path} #{target_array.join(' ')}"
   puts target_command

    target_process = spawn(env, *target_array, out: STDOUT, err: STDOUT)
    writer.close
    Process.detach(target_process)
    sleep(10)
    $workers = processes
  end
  # run request to the inference server

  raw_payload = {
  V1: 0.1, V2: -0.5, V3: 1.2, V4: -2.0, V5: 0.3, V6: 0.6, V7: -0.9, V8: 1.5, V9: -0.7, V10: 0.8,
  V11: -1.1, V12: 0.4, V13: -0.2, V14: 0.9, V15: -0.8, V16: 1.0, V17: -0.3, V18: 0.7, V19: -0.5,
  V20: 0.2, V21: -1.4, V22: 0.5, V23: -0.6, V24: 0.3, V25: -0.9, V26: 1.1, V27: -1.2, V28: 0.4,
  Amount: 123.45 }

  payload = raw_payload.to_json

  command = "seq 1 #{requests} | xargs -P #{requests} -I {} curl -X POST #{target} -H 'Content-Type: application/json' -d '#{payload}'"
  puts command
  time_start = Time.now
  raw_result = `#{command}`
  inference_time = Time.now - time_start
  requests_per_second = requests / inference_time
  server_raw_output = "" #writer.read

  `pkill gunicorn`

  # extract benchmark results
  error = (`echo "#{server_raw_output}" | grep "CUDA run out of memory"` << `echo "#{server_raw_output}" | grep -i "error | grep -vi dictionary"`)[0..499]

  # collect result
  collect = { inference_time: inference_time, requests_per_second: requests_per_second, error: error.chomp, input_elements: raw_payload.size }
  iterate = { iteration: iterator[:iteration], processes: processes, requests: requests, device: device }
  startup = { command: command.gsub("'", "''"), target_app_command: target_command, target_app_code: File.read(config[:startup_target_application]).gsub("'", "''")}

  return { startup: startup, iterate: iterate, collect: collect }
end
