
# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimensions(config)
  [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_processes].to_a,
    config[:iterate_requests].to_a,
    config[:iterate_images].to_a
  ]
end

# CUSTOMIZE: give names to the dimensions, as a comma-separated list
def dimension_naming
  [ :iteration, :processes, :requests, :image ]
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

  # get resolution of the current image
  image_resolution = `file #{iterator[:image]} | grep -Eo '[0-9]+x[0-9]+'`
  # get format of the current image
  image_format = `file #{iterator[:image]} | awk '{print $2}'`
  # get full metadata of the current image
  image_metadata = `file #{iterator[:image]} | awk '{$1=""; print substr($0, 2)}'`

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]
  processes = iterator[:processes]
  requests = iterator[:requests]
  app = config[:startup_target_application]
  app = app.end_with?('.py') ? app.chomp('.py') : app
  app_dir = File.dirname(app)
  app_name = File.basename(app)
  target_command = ""
  device = iterator[:device]

  reader, writer = IO.pipe
  # reload the inference server if the iterator has updated its parameters: device or workers
  if $workers != processes or $device != device
   target_array = [
      "gunicorn",
      "-k", "uvicorn.workers.UvicornWorker",
      "-w", processes.to_s,
      "-b", "0.0.0.0:8080",
      "--pid", "gunicorn.pid",
      "--chdir", app_dir,
      "#{app_name}:app"
   ]
   env = { "DEVICE" => device }

   target_command = "DEVICE=#{device} #{target_array.join(' ')}"

    target = spawn(env, *target_array, out: writer, err: writer)
    writer.close
    Process.detach(target)
    sleep(10)
    $workers = processes
  end
  # run request to the inference server
  command = "seq 1 #{requests} | xargs -P #{requests} -I {} curl -X POST 'http://localhost:8080/predict/' -H 'Content-Type: application/octet-stream' --data-binary @#{iterator[:image]} 2>&1"
  time_start = Time.now
  raw_result = `#{command}`
  inference_time = Time.now - time_start
  server_raw_output = "" #reader.read

  # extract benchmark results
  error = (`echo "#{server_raw_output}" | grep "CUDA run out of memory"` << `echo "#{server_raw_output}" | grep -i "error | grep -vi dictionary"`)[0..499]

  # collect result
  collect = { inference_time: inference_time, error: error, image_resolution: image_resolution, image_format: image_format, image_metadata: image_metadata }
  iterate = { iteration: iterator[:iteration], processes: processes, requests: requests, device: device }
  startup = { command: command.gsub("'", "''"), target_app_command: target_command, target_app_code: File.read(config[:startup_target_application]).gsub("'", "''")}

  return { startup: startup, iterate: iterate, collect: collect }
end
