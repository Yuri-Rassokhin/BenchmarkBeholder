require 'optparse'

class Options

attr_reader :mode, :hosts, :workload

def initialize(logger, argv)
  @logger = logger
  @hosts = "127.0.0.1"
  @mode = "launch"
  @workload = nil
  @hooks = Dir.entries("./sources/hooks") - %w[. ..]
  options_parse(argv)
end

def check_hook(hook)
  @logger.error "unknown workload '#{hook}'" if !@hooks.include?(hook)
  @logger.error "incorrect integration of '#{hook}', invocation file is missing" if !File.exist?("./sources/hooks/#{hook}/invocation.rb")
  @logger.error "incorrect integration of '#{hook}', parameters file is missing" if !File.exist?("./sources/hooks/#{hook}/parameters.rb")
end

private

def options_parse(argv)
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: bbh [-h] [-p] [-s] [workload_file] [host] ..."

    opts.on('-h', '--help', 'Show help') do
      @logger.info opts
      exit
    end

    opts.on('-p', '--projects', 'Show projects') do
      options[:projects] = true
    end

    opts.on('-s', '--space', 'calculate parameter space size of the workload on host(s)') do
      options[:space] = true
    end
  end

  # Extract options and remaining arguments
  args = parser.parse(ARGV)

  # Handle cases based on parsed options
  if options[:projects]
    projects_show
    exit
  elsif options[:set]
    if args.empty?
      @logger.error "-s requires workload file and at least one host"
      exit 1
    end
    @workload = args.shift
    @hosts = args
  else
    if args.empty?
      @logger.error "missing arguments, use -h for help"
      exit 1
    end
    @workload = args.shift
    @hosts = args
  end
end

def projects_show
  client = Mysql2::Client.new(default_file: File.expand_path('~/.my.cnf'))
  begin
    results = client.query("SELECT * FROM projects")
    if results.any?
      # Extract headers and calculate column widths
      headers = results.fields
      rows = results.map(&:values)

      column_widths = headers.map.with_index do |header, index|
        [
          header.length,
          *rows.map { |row| row[index].to_s.length }
        ].max
      end

      # Helper method to format rows
      format_row = lambda do |row|
        row.each_with_index.map { |value, index| value.to_s.ljust(column_widths[index]) }.join(" | ")
      end

      # Print header
      @logger.info format_row.call(headers)

      # Print a separator line
      @logger.info column_widths.map { |width| "-" * width }.join("-+-")

      # Print each row
      rows.each do |row|
        @logger.info format_row.call(row)
      end
    else
      @logger.info "No projects available"
    end
  rescue Mysql2::Error => e
    @logger.error "#{e.message}"
  ensure
    client.close if client
  end
  exit 0
end

end

