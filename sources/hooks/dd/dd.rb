class Dd < Collector

def initialize(config, url, mode, logger, series)
  super(config, url, mode, logger, series)
end

require_relative 'launch'

def get_dynamic_metrics
  get_gpu_consumption
  get_cpu_consumption
  get_storage_consumption
end

def schema
  "
    iterate_operation varchar(50) not null first,
    collect_bandwidth_gbytesps double not null after iterate_operation
  "
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

