
class Object_storage_coco_reading < Collector

def launch(config)

def cartesian(dimensions)
  filtered_dimensions = dimensions.reject(&:empty?)
  cartesian = filtered_dimensions.size > 1 ? filtered_dimensions.inject(&:product) : filtered_dimensions.first.map { |e| [e] }
  # Return an enumerator if no block is given
  return cartesian.map(&:flatten).to_enum unless block_given?
  # Yield each combination if a block is given
  cartesian.map(&:flatten).each do |combination|
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
def push(config, output, iterators)
  query = <<-SQL
      collect_bandwidth = '#{output[:bandwidth]}',
      collect_time = '#{output[:time]}',
      collect_size = '#{output[:size]}',
      startup_command = '\"#{iterators[:command]}\"',
      iterate_iteration = '#{iterators[:iteration]}'
  SQL
  push!(query, config)
end

  require 'open3'
  require 'mysql2'

  # CUSTOMIZE: add the modules required for your hook
  require 'oci'
  require 'pathname'

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]

  # NOTE: adding workload-specific initialization of the target
  oci_conf = OCI::ConfigFileLoader.load_config()
  object_storage = OCI::ObjectStorage::ObjectStorageClient.new(config: oci_conf)
  namespace = config[:startup_namespace]
  bucket_name = config[:startup_target]
  response = object_storage.list_objects(namespace, bucket_name)

  # CUSTOMIZE: add your dimensions here in the form config[:my_option].to_a
  dimensions = [
    (1..config[:iterate_iterations]).to_a
  ]

  cartesian(dimensions).each  do |iteration|
    response.data.objects.each do |object|
      object_name = object.name
      start_time = Time.now
      object_response = object_storage.get_object(namespace, bucket_name, object_name)
      File.open('/dev/null', 'wb') { |null_file| null_file.write(object_response.data) }
      elapsed_time = Time.now - start_time
      size = object_response.headers["content-length"].to_i
      bandwidth_mbps = (size / 1024.0 / 1024.0) / elapsed_time
      #puts "Read #{object_name}: #{bandwidth_mbps} MB/sec"
      output = { bandwidth: bandwidth_mbps, size: size, time: elapsed_time }
      language = "ruby"
      command = "object_response = object_storage.get_object(namespace, bucket_name, object_name) File.open('/dev/null', 'wb') { |null_file| null_file.write(object_response.data) }"
      push(config, output, {iteration: iteration, command: command.gsub("'", "''"), language: language })
    end
  end
end

end
