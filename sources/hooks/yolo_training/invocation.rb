
# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimensions(config)
  [
    (1..config[:iterate_iterations]).to_a
  ]
end

# CUSTOMIZE: give names to the dimensions, as a comma-separated list
def dimension_naming
  [ :iteration ]
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

  target = config[:startup_target]
  model = config[:startup_model]
  dataset = config[:startup_dataset]
  epochs = config[:startup_epochs]
  image_size = config[:startup_image_size]
  batch = config[:startup_batch]
  device = config[:startup_device]

  if model.include? "yolov5"
    target_command = "python3 train.py --img #{image_size} --batch #{batch} --epochs #{epochs} --data #{dataset} --weights #{model}.pt --device #{device}"
  else
    target_command = "#{target} task=detect mode=train model=#{model}.pt data=#{dataset} epochs=#{epochs} imgsz=#{image_size} batch=#{batch} device=#{device}"
  end

  time_start = Time.now
  raw_result = `#{target_command}`
  training_time = Time.now - time_start

  # extract benchmark results

  # collect result
  collect = { training_time: training_time }
  iterate = { iteration: iterator[:iteration] }
  startup = { command: target_command.gsub("'", "''"), model: model, dataset: dataset, epochs: epochs, image_size: image_size, batch: batch, device: device }

  return { startup: startup, iterate: iterate, collect: collect }
end
