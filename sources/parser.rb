class Parser

def helper(option, hooks)

  if ["help", "-h", "--help", nil].include?(option)
    puts <<~USAGE
      Usage:
      Show this help: bbh { -h, --help, help }
      Show supported benchmarks & environments: bbh { -v, --version, version }
      Show registered projects: bbh -p
      Launch benchmark: bbh <benchmark> <configuration_file>
    USAGE
    exit 0
  end

  if option == "-p"
    puts "Available projects:"
    Open3.popen3("mysql -B -e \"select * from BENCHMARKING.projects;\"") do |stdin, stdout, stderr, wait_thr|
      puts stdout.read
    end
    exit 0
  end

if ["version", "-v", "--version"].include?(option)
    puts <<~VERSION
    BenchmarkBeholder
    
    >>> Registered benchmarks
    #{hooks.map { |h| "#{h}" }.join("\n")}
    
    >>> Supported cloud environments
    Oracle Cloud Infrastructure (OCI), all compute shapes
    
    >>> Supported storage
    Raw block device
    RAID by mdadm
    tmpfs
    ramfs
    brd
    Local filesystems: XFS, ext3/4, btrfs, etc
    Shared filesystems: GlusterFS, NFS
    
    >>> Supported operating systems
    Ubuntu, all versions
    RHEL, Fedora, Oracle Linux, and derivatives, all versions
    
    >>> Configuration requirements
    Passwordless SSH for your user to benchmark nodes
    Your user is sudoer on all benchmark nodes
    All benchmark nodes are identical
    Benchmark nodes can access the central node via MySQL ports
    Package dependencies on the benchmark nodes are installed
  VERSION
  exit
end

end

def initialize(logger, conf_file)

  @logger = logger
  @conf_file = conf_file

  @hooks_dir = "./sources/hooks/"
  @hooks = Dir.entries(@hooks_dir) - %w[. ..]
  helper(@conf_file, @hooks)

  # check if configuration file available
  @logger.error("missing configuration file") if conf_file.nil? || conf_file.empty?
  @logger.error("configuration file '#{conf_file}' not found") if !File.exist?(conf_file)
end

def check(hook)
  @logger.note("benchmark '#{hook}'") do
  if !@hooks.include?(hook)
    @logger.error("unknown benchmark #{hook}")
  elsif @conf_file.nil?
    @logger.error("configuration file isn't specified")
  elsif !File.exist?(@conf_file)
    @logger.error("configuration file is missing")
  end
end

end

end
