
require 'mysql2'
require 'open3'

class Collector < Agent

  attr_reader :infra_static

def initialize(config, url, mode_raw, logger, series, target)
  @config = config
  super(nil, url)
  @logger = logger

  platform = run!(:guess_platform)
  shape = run!(:guess_shape)
  src = config.get(:startup_target)
  main_dev = run!(:main_device, src)
#  main_dev = File.basename(src) if main_dev == "udev"
#  main_dev_name = File.basename(main_dev)
#  filesystem = run!(:get_filesystem, src)
  if target.has_device?
    device_info = run!(:check_device, src)
  else
    device_info = { filesystem: "NA", type: "NA", members: "NA", aggregated: false }
  end
  filesystem = device_info[:filesystem]
  type = device_info[:type]
  members = device_info[:members].split

#  puts "src: #{src}, main_dev: #{main_dev}, raid_info: #{raid_info}"
#  puts "fs: #{filesystem}"
  @infra_static = {
    series: series,
    src: src,
    url: url,
    password: nil,
    number_installed_gpus: run!(:count_gpu),
    host: run!(:hostname),
    release: run!(:os_release),
    kernel: run!(:kernel_release),
    arch: run!(:cpu_arch),
    cpu: run!(:cpu_model),
    cores: run!(:core_count),
    ram: run!(:cpu_ram_amount),
    main_dev: main_dev,
#    main_dev_name: main_dev_name,
    filesystem: filesystem,
    raid_members: members,
    raid_members_amount: members.size,
    root_dev: device_info[:aggregated] ? get_aggregated_root_dev(main_dev) : get_root_dev(main_dev),
    aggregated: device_info[:aggregated],
    storage_type: type,
    fs_block_size: run!(:get_filesystem_block_size, main_dev, filesystem),
    fs_mount_options: get_filesystem_mount_options(main_dev),
    platform: platform,
    shape: shape,
    subshape: "",
    device: case filesystem
           when "ramfs", "tmpfs" then "RAM"
           when "nfs" then "NFS"
           when "fuse.glusterfs" then "GlusterFS"
           else "NA"
           end,
    gds_supported: run!(:check_gds, filesystem),
#   gpu_info: run!(:get_gpu_consumption, @number_installed_gpus),
#   @cpu_consumption = run!(:get_cpu_consumption)
#   @storage_consumption = run!(:get_storage_consumption, @device, @main_dev)
    mode: mode_raw == "single" ? "a single" : mode_raw,
    target: filesystem == "N/A" ? "raw device #{src}" : filesystem,
    get_nvidia_versions: run!(:get_nvidia_versions),
    series_description: ""
  }
  @infra_static[:series_description] = description_eval(config.get(:series_description))

end

def completed
  if @error_counter == 0
    puts "Series #{@series} completed"
  else
    puts "Series #{@series} completed with errors"
  end
end
  #File.delete(conf_file)

private

# gets root device name for a given partiion; NOTE: it doesn't work with RAID/LVM
def get_root_dev(main_dev)
  File.basename(main_dev).gsub(/\d+$/, '')
end

def get_aggregated_root_dev(main_dev)
  `sudo lvs --segments -o +devices #{main_dev} | tac | head -1 | awk '{print $7}' | sed 's/[0-9].*$//'`
end

def description_eval(description)
  target = @infra_static[:target]
  mode = @infra_static[:mode]
  shape = @infra_static[:shape]
  eval("\"" + description + "\"")
end

def extract()
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  @logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

def push()
  file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
  @logger.fatal("(#{file} line #{line}): method '#{__method__}' called must be implemented in benchmark-specific heir")
end

def launch(config)

require 'open3'
require 'mysql2'
require 'net/http'
require 'json'

at_exit do
  puts "\nExiting at #{$step/$total_steps}% finished"
end

# Trap common termination signals
%w[INT TERM].each do |signal|
  Signal.trap(signal) do
    puts "\nReceived #{signal} signal"
    exit
  end
end

$total_steps = config[:parameter_space_size]

def human_readable_time(seconds)
  days = (seconds / (24 * 3600)).to_i
  hours = (seconds % (24 * 3600) / 3600).to_i
  minutes = (seconds % 3600 / 60).to_i
  readable = []
  readable << "#{days} days" if days > 0
  readable << "#{hours} hours" if hours > 0
  readable << "#{minutes} minutes" if minutes > 0
  readable.empty? ? "less than a minute" : readable.join(" ")
end

def iterator_format(iterator, config)
  seconds_left = ( $time_passed == 0 ? "TBD" : human_readable_time((($time_passed)/$step)*(config[:parameter_space_size]-$step).to_i) )
  iter = ""
  iterator.each { |it, val| iter << "   #{it.to_s.gsub(':', '')} #{val}NEW" }
  "Invocation #{$step} of #{config[:parameter_space_size]}NEWTime left: #{seconds_left}NEWParameters:NEW#{iter}"
end

def message(format, body, config)
  case format
  when :header
    result = "Starting benchmarkNEW#{body}"
  when :footer
    result = "Completed #{body}"
  when :iterator
    result = iterator_format(body, config)
  end
  puts result
end

'''
def msg(text)
    return if not $config[:chat_id]
    uri = URI("https://api.telegram.org/bot#{$config[:token]}/sendMessage")
    params = {
      chat_id: $config[:chat_id],
      text: text
    }
    response = Net::HTTP.post_form(uri, params)
  rescue StandardError => e
    puts "Error: #{e.message}"
end
'''
def msg(text)
  return if not $config[:chat_id]

  uri = URI("https://api.telegram.org/bot#{$config[:token]}/sendMessage")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
  request.body = { chat_id: $config[:chat_id], text: text }.to_json

  response = http.request(request)
rescue StandardError => e
  puts "Error: #{e.message}"
end

# Simple method to capture and resend all output (stdout and stderr) in real-time
def capture
  # Create a single pipe for both stdout and stderr
  combined_r, combined_w = IO.pipe

  # Save the original stdout and stderr
  original_stdout = $stdout
  original_stderr = $stderr

  begin
    # Redirect stdout and stderr to the same write end of the pipe
    $stdout = combined_w
    $stderr = combined_w

    # Start a thread to read and output data as it comes
    output_thread = Thread.new do
      while (line = combined_r.gets)
        msg(line.gsub("NEW", "\n"))
#        File.open('output.log', 'a') { |file| file.write(line) }  # Write combined output to a file
      end
    end

    # Run the block of code
    yield

  ensure
    # Restore original stdout and stderr
    $stdout = original_stdout
    $stderr = original_stderr

    combined_w.close  # Close the write end of the pipe

    # Wait for the thread to finish reading
    output_thread.join

    combined_r.close
  end
end

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
    filtered_dimensions.first.each { |e| yield([e]) }
    return
  end

  # Handle multiple dimensions (Cartesian product)
  cartesian = filtered_dimensions.inject(&:product).map(&:flatten)

  # Return an enumerator if no block is given
  return cartesian.to_enum unless block_given?

  # Yield each combination as a single array
  cartesian.each do |combination|
    yield combination
  end
end

def push!(query, config)
  mysql = Mysql2::Client.new(default_file: File.expand_path('~/.my.cnf'))
  # consumption_cpu = '#{cpu_consumption}',
  # consumption_storage_tps = '#{storage_tps}',
  generic_query = <<-SQL
      insert into #{config[:series_benchmark]} set
      project_code = '#{config[:project_code]}',
      project_tier = '\"#{config[:project_tier]}\"',
      series_id = '#{config[:series]}',
      series_description = '\"#{config[:series_description]}\"',
      series_benchmark = '#{config[:series_benchmark]}',
      startup_actor = '#{config[:startup_actor]}',
      infra_host = '#{config[:host]}',
      infra_platform = '#{config[:platform]}',
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
      infra_gds_supported = '#{config[:gds_supported]}'
  SQL

  formatted_query = query.lines.map.with_index do |line, index|
    index == query.lines.size - 1 ? line.strip : "#{line.strip},"
  end.join("\n") << ";"

  mysql.query(generic_query << "," << formatted_query)
end

# construct workload-specific part of the output data for the database
def push(config, collect, iterate, startup)
  query = ""
  collect.each_key { |p| query << "collect_#{p} = '#{collect[p]}'\n" }
  iterate.each_key { |p| query << "iterate_#{p} = '#{iterate[p]}'\n" }
  startup.each_key { |p| query << "startup_#{p} = '#{startup[p]}'\n" }
  push!(query, config)
end

def platform_title(platform_name)
  case platform_name
  when "oci"
    "OCI"
  when "azure"
    "MS Azure"
  when "aws"
    "AWS"
  else "unknown" 
  end
end

def dim(vector)
    Hash[dimension_naming.zip(vector)]
end
  
  $config = config
  $step = 1
  $start_time = Time.now
  $time_passed = 0
  prepare(config)
  capture do
    message(:header, "NEWSeries: #{config[:series]}NEWNEWTier: #{config[:project_tier].upcase}NEWNEWWorkload: #{config[:series_description]}NEWNEWPlatform: #{platform_title(config[:platform])}", config)
    cartesian(dimensions(config)) do |vector|
        start_time = Time.now
        iterator = dim(vector)
        message(:iterator, iterator, config)
        result = invocation(config, iterator)
        push(config, result[:collect], result[:iterate], result[:startup])
        $step += 1
        $time_passed += Time.now - start_time
    end
  end
  message(:footer, "#{config[:tier]} series #{config[:series]} of #{config[:series_description]} on the host #{config[:host]}", config)
end

end
