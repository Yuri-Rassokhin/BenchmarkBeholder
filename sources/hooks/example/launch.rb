module Launch

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
      project_code = '#{config[:project_code]}',
      project_tier = '\"#{config[:project_tier]}\"',
      series_id = '#{config[:series]}',
      series_description = '\"#{config[:series_description]}\"',
      series_benchmark = '#{config[:series_benchmark]}',
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

  formatted_query = query.lines.map.with_index do |line, index|
    index == query.lines.size - 1 ? line.strip : "#{line.strip},"
  end.join("\n") << ";"

  mysql.query(generic_query << formatted_query)
end

# construct workload-specific part of the output data for the database
def push(config, collect, iterate, startup)
  query = ""
  collect.each_key { |p| query << "collect_#{p} = '#{collect[p]}'\n" }
  iterate.each_key { |p| query << "iterate_#{p} = '#{iterate[p]}'\n" }
  startup.each_key { |p| query << "startup_#{p} = '#{startup[p]}'\n" }
  puts query
  push!(query, config)
end


  # CUSTOMIZE: add 'require' for the modules required for your hook

  # CUSTOMIZE: add names of your iteratables
  cartesian(dimension_space_create(config)).each do |iteration|

    # CUSTOMIZE: this is the main part, add your semantics of the benchmark invocation
    command = "sleep 5 2>&1"
    raw_result = `#{command}`

    # CUSTOMIZE: gather your collectable parameters
    collect = { }

    # CUSTOMIZE: add your iteratable parameters
    iterate = { iteration: iteration }

    startup = { command: command.gsub("'", "''"), language: "bash" }
    push(config, collect, iterate, startup)
  end
end

# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimension_space_create(config)
  [
    (1..config[:iterate_iterations]).to_a
  ]
end

end
