
class Database

def initialize
  @table = nil
  @client = Mysql2::Client.new(default_file: '~/.my.cnf')
  @schema = nil
end

def project_codes
    return `mysql -N -B -e "select code from bbh.projects;"`.split("\n").join.tr("\"",'')
end

def projects
  warning("this yet to be implemented")
end

def table_set(name, schema)
  raise "Benchmark database table cannot be nil" unless name
  raise "Benchmark database table schema cannot be nil" unless schema

  @table = name
  @schema = schema
  table_create if !table?
end

private

def table?
  raise "Database table has not been specified" unless @table
  result = @client.query("select count(*) as table_exists from information_schema.tables where table_schema = 'bbh' and table_name = '#{@table}';")
  (result.first['table_exists'] > 0) ? true : false
end

def table_create
  raise "Database table has not been specified" unless @table
  table_create_generic
  table_add_specific
end

# All configuration parameters and (extended) database columns are grouped as
# PROJECT: Description of a project, which is a collection of related series, potentially different benchmarks in different setups
# SERIES: Description of a series, which is a single invocation of BBH for a given benchmark in a given setup
# STARTUP: Configuration of HOW to execute the series (which executable, which media if any, how to treat grace period if any, etc)
# ITERATE: Parameters the benchmark iterates over
# COLLECT: Metrics collected during the benchmark

def table_add_specific
  @client.query("alter table bbh.#{@table} #{@schema}")
end

def table_create_generic
  @client.query(<<~SQL)
    CREATE TABLE bbh.#{@table} (
      project_description VARCHAR(500),
      project_code VARCHAR(50),
      project_tier VARCHAR(50),

      series_id INT NOT NULL,
      series_benchmark VARCHAR(50) NOT NULL,
      series_description VARCHAR(500),
      series_owner_name VARCHAR(50) NOT NULL,
      series_owner_email VARCHAR(50) NOT NULL,

      startup_executable VARCHAR(100) NOT NULL,
      startup_command VARCHAR(500) NOT NULL,

      iterate_scheduler VARCHAR(50),
      iterate_iteration INT NOT NULL,
      
      infra_host VARCHAR(50) NOT NULL,
      infra_shape VARCHAR(50) NOT NULL,
      infra_filesystem VARCHAR(50) NOT NULL,
      infra_storage VARCHAR(50) NOT NULL,
      infra_device VARCHAR(50) NOT NULL,
      infra_drives INT NOT NULL,
      infra_architecture VARCHAR(10) NOT NULL,
      infra_os VARCHAR(50) NOT NULL,
      infra_kernel VARCHAR(50) NOT NULL,
      infra_cpu VARCHAR(50) NOT NULL,
      infra_cores INT NOT NULL,
      infra_ram INT NOT NULL,

      collect_error VARCHAR(500)
    )
  SQL
end

end
