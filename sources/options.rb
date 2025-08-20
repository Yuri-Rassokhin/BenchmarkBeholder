require 'optparse'

class Options

attr_reader :workload, :space_mode

def initialize(logger, argv)
  @logger = logger
  @hosts = []
  @space_mode = false
  @workload = nil
  @hooks = Dir.entries("./sources/hooks") - %w[. ..]
  options_parse(argv)
end

private

def options_parse(argv)
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: bbh { -v | -h | [-s] sweep_file }"

    opts.on('-h', '--help', 'Show help') do
      opts.to_s.each_line { |line| @logger.info line.chomp }
      exit 0
    end

    opts.on('-s', '--space', 'Calculate parameter space size of the workload on host(s)') do
      options[:space] = true
    end

    opts.on('-v', '--version', 'Show supported workloads and environments') do
      options[:version] = true
    end
  end

  # Extract options and remaining arguments
  args = parser.parse(ARGV)

  # Handle cases based on parsed options
  if options[:version]
    version_show
    exit 0
  elsif options[:space]
    if args.empty?
      @logger.error "-s requires sweep file"
    end
    @space_mode = true
    @workload = args.shift
  else
    if args.empty?
      @logger.error "missing arguments, use -h for help"
    end
    @workload = args.shift
  end
end

def version_show
  @logger.info "### BenchmarkBeholder ###"
  @logger.info "home page: https://github.com/Yuri-Rassokhin/BenchmarkBeholder"
  @logger.info "supported workloads: #{@hooks.join(", ")}"
  @logger.info "supported cloud platforms: OCI, AWS, Azure"
  @logger.info "supported local filesystems: XFS, ext3/4, btrfs, and any other POSIX-compliant"
  @logger.info "supported shared filesystems: GlusterFS, NFS, BeeGFS"
  @logger.info "supported special storage: raw block device, mdadm RAID, tmpfs, ramfs, brd, vboxsf"
  @logger.info "supported operating systems: Ubuntu, RHEL/CentOS, Fedora, Oracle Linux"
end

end

