class Parser < Object

  attr_reader :mode, :conf_file

def initialize(logger, argv)

  @mode = :launch
  @argv = argv
  @logger = logger

  @option = @argv[0]
  @conf_file = nil

  @hooks_dir = "./sources/hooks/"
  @hooks = Dir.entries(@hooks_dir) - %w[. ..]
  helper(@option, @hooks)
  @conf_file = argv[0] if !@conf_file

  # check if configuration file available
  @logger.error("missing configuration file") if @conf_file.nil? || @conf_file.empty?
  @logger.error("configuration file '#{@conf_file}' not found") if !File.exist?(@conf_file)
end

def check(hook)
    @logger.info("Checking workload hook '#{hook}'")
    if !@hooks.include?(hook)
      @logger.error("unknown benchmark #{hook}")
    elsif @conf_file.nil?
      @logger.error("configuration file isn't specified")
    elsif !File.exist?(@conf_file)
      @logger.error("configuration file is missing")
    end
end

private

def helper(option, hooks)

  if ["help", "-h", "--help", nil].include?(option)
    puts <<~USAGE
      Usage:
      Show this help: bbh { -h, --help, help }
      Show supported benchmarks & environments: bbh { -v, --version, version }
      Show registered projects: bbh { -p, --projects, projects }
      Calculate parameter space: bbh { -s, --space, space } <configuration_file>
      Launch benchmark: bbh <benchmark> <configuration_file>
    USAGE
    exit 0
  end

  if ["-p", "projects", "--projects"].include?(option)
    puts "Available projects:"
    Open3.popen3("mysql -B -e \"select * from BENCHMARKING.projects;\"") do |stdin, stdout, stderr, wait_thr|
      puts stdout.read
    end
    exit 0
  end

  if [ "space", "-s", "--space" ].include?(option)
    @mode = :space
    @conf_file = @argv[1]
  end

  if [ "version", "-v", "--version" ].include?(option)
      puts <<~VERSION
      BenchmarkBeholder

      >>> Registered benchmarks
      #{hooks.map { |h| "#{h}" }.join("\n")}

      >>> Supported cloud environments
      Oracle Cloud Infrastructure (OCI), all compute shapes

      >>> Supported storage
      Special storage: Raw block device, RAID by mdadm, tmpfs, ramfs, brd, vboxsf
      Local filesystems: XFS, ext3/4, btrfs, etc.
      Shared filesystems: GlusterFS, NFS, BeeGFS

      >>> Supported operating systems
      Ubuntu, RHEL/CentOS, Fedora, Oracle Linux

      >>> Configuration requirements
      Passwordless SSH for your user to benchmark nodes
      Your user is sudoer on all benchmark nodes
      All benchmark nodes are identical
      Benchmark nodes can access the central node via MySQL ports
      Package dependencies on the benchmark nodes are installed
    VERSION
    exit 0
  end
end

end
