
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
      infra_filesystem_block_size = '\"#{config[:fs_block_size]}\"',
      infra_filesystem_mount_options = '\"#{config[:fs_mount_options]}\"',
      infra_storage = '\"#{config[:storage_type]}\"',
      infra_device = '\"#{config[:device]}\"',
      infra_drives = '\"#{config[:raid_members_amount]}\"',
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

  # NOTE: adding workload-specific modules
  require 'oci'
  require 'pathname'

  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]

  # NOTE: adding workload-specific initialization of the target
  oci_conf = OCI::ConfigFileLoader.load_config()
  object_storage = OCI::ObjectStorage::ObjectStorageClient.new(config: oci_conf)
  namespace = 'fr9qm01oq44x'
  bucket_name = 'coco-2017-images'
  response = object_storage.list_objects(namespace, bucket_name)

  # Define parameter space, a Cartesian of those parameters we want to iterate over
  dimensions = [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_operations].to_a
  ]

  # NOTE: loop is a template, workload-specific iterators inherited from the 'dimensions' variable
  dimensions.inject(&:product).map(&:flatten).each do |iteration|
    response.data.objects.each do |object|
      object_name = object.name
      start_time = Time.now
      object_response = object_storage.get_object(namespace, bucket_name, object_name)
      File.open('/dev/null', 'wb') { |null_file| null_file.write(object_response.data) }
      elapsed_time = Time.now - start_time
      size = object_response.headers["content-length"].to_i
      bandwidth_mbps = (size / 1024.0 / 1024.0) / elapsed_time
      puts "Read #{object_name}: #{bandwidth_mbps} MB/sec"
      output = { bandwidth: bandwidth_mbps, error: "" }
      command = "RUBY: object_response = object_storage.get_object(namespace, bucket_name, object_name) File.open('/dev/null', 'wb') { |null_file| null_file.write(object_response.data) }"
      push(config, output, {iteration: iteration, command: command.gsub("'", "''"), scheduler: "NA" , operation: "read" })
    end
  end
end

end
