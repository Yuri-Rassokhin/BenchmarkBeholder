
class Database < Object

require 'io/console'

def initialize(logger)
  @logger = logger
  @table = nil
  @client = Mysql2::Client.new(default_file: '~/.my.cnf')
  @schema = nil
end

def project_codes
    return `mysql -N -B -e "select code from projects;"`.split("\n").join.tr("\"",'')
end

def table_set(hook)
  raise "Benchmark database table cannot be nil" unless hook
  @table = hook
  @schema = schema_set(hook)
  table_create if !table?
end

def table_add_io_schedulers
  return if table?
  raise "Database table has not been specified" unless @table
#  puts "alter table #{@table} add iterate_scheduler varchar(50) not null;"
  @client.query("alter table #{@table} add iterate_scheduler varchar(50) not null;")
end

private

def schema_set(hook)
  input = File.expand_path("../hooks/#{hook}/parameters.rb", __dir__)
  require input
  self.extend(Object.const_get(:Parameters))
  database_parameters
end

def table?
  raise "Database table has not been specified" unless @table
  current_db = @client.query("SELECT DATABASE()").first["DATABASE()"]
  result = @client.query("select count(*) as table_exists from information_schema.tables where table_schema = '#{current_db}' and table_name = '#{@table}';")
  (result.first['table_exists'] > 0) ? true : false
end

def table_create
  raise "Database table has not been specified" unless @table
  db_admin("creation") do
    table_create_generic
    table_add_specific
    create_triggers
  end
end

def create_triggers
  create_trigger_credentials
  create_trigger_project
end

def create_trigger_project
trigger_add_project_description = <<-SQL
CREATE TRIGGER add_project_description
BEFORE INSERT ON #{@table}
FOR EACH ROW
BEGIN
    DECLARE project_description VARCHAR(500) DEFAULT 'undefined';
    SELECT description INTO project_description
    FROM projects
    WHERE code = NEW.project_code
    LIMIT 1;
    SET NEW.project_description = project_description;
END;
SQL
@client.query(trigger_add_project_description)
end

def create_trigger_credentials
trigger_add_credentials = <<-SQL
CREATE TRIGGER add_credentials
BEFORE INSERT ON #{@table}
FOR EACH ROW
BEGIN
    DECLARE user_name VARCHAR(100) DEFAULT 'undefined';
    DECLARE user_email VARCHAR(100) DEFAULT 'undefined';
    DECLARE plain_username VARCHAR(50);
    SET plain_username = SUBSTRING_INDEX(USER(), '@', 1);
    SELECT name, email INTO user_name, user_email
    FROM users
    WHERE username = plain_username
    LIMIT 1;
    SET NEW.series_owner_name = user_name;
    SET NEW.series_owner_email = user_email;
END;
SQL
@client.query(trigger_add_credentials)
end

# All configuration parameters and (extended) database columns are grouped as
# PROJECT: Description of a project, which is a collection of related series, potentially different benchmarks in different setups
# SERIES: Description of a series, which is a single invocation of BBH for a given benchmark in a given setup
# STARTUP: Configuration of HOW to execute the series (actor, target, how to treat grace period if any, etc)
# ITERATE: Parameters the benchmark iterates over
# COLLECT: Metrics collected during the benchmarking

def table_add_specific
  @client.query("alter table #{@table} #{@schema}")
end

def table_create_generic
  @client.query(<<~SQL)
    CREATE TABLE #{@table} (
      project_description VARCHAR(500),
      project_code VARCHAR(50),
      project_tier VARCHAR(50),

      series_id INT NOT NULL,
      series_benchmark VARCHAR(50) NOT NULL,
      series_description VARCHAR(500),
      series_owner_name VARCHAR(50),
      series_owner_email VARCHAR(50),

      startup_actor VARCHAR(100) NOT NULL,
      startup_command VARCHAR(500) NOT NULL,
      startup_language VARCHAR(20) NOT NULL,

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
      infra_ram BIGINT NOT NULL
    )
  SQL
end

def db_admin(operation, &block)
  regular_client = @client
  @logger.info("Admin rights requested for the #{operation} of the table '#{@table}'")
  # Ask for ADMIN explicitly
  print "Enter ADMIN username: "
  username = IO.console.gets.chomp
  print "Enter ADMIN password: "
  password = IO.console.noecho(&:gets).chomp
  puts # Move to the next line after password input

  begin
    @client = Mysql2::Client.new(
      username: username,
      password: password,
      default_file: File.expand_path('~/.my.cnf')
    )
    yield
  rescue Mysql2::Error => e
    @logger.error("Can't access database as admin: #{e.message}")
  ensure
    @client = regular_client
  end
end

end
