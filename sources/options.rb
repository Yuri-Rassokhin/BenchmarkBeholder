require 'optparse'

class Options

attr_reader :mode, :hosts, :workload, :debug

def initialize(logger, argv)
  @logger = logger
  @hosts = [ "127.0.0.1" ]
  @mode = "launch"
  @workload = nil
  @hooks = Dir.entries("./sources/hooks") - %w[. ..]
  @debug = false
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
    opts.banner = "Usage: bbh [-v] [-h] [-p] [-s] [workload_file] [host] ..."

    opts.on('-h', '--help', 'Show help') do
      opts.to_s.each_line { |line| @logger.info line.chomp }
      exit
    end

    opts.on('-d', '--debug', 'Output debugging information') do
      @debug = true
    end

    opts.on('-s', '--space', 'calculate parameter space size of the workload on host(s)') do
      options[:space] = true
    end

    opts.on('-v', '--version', 'show supported workloads and environments') do
      options[:version] = true
    end
  end

  # Extract options and remaining arguments
  args = parser.parse(ARGV)

  # Handle cases based on parsed options
  if options[:version]
    version_show
    exit
  elsif options[:space]
    if args.empty?
      @logger.error "-s requires workload file and at least one host"
      exit 1
    end
    @mode = "space"
    @workload = args.shift
    @hosts ||= args
  else
    if args.empty?
      @logger.error "missing arguments, use -h for help"
      exit 1
    end
    @workload = args.shift
    @hosts ||= args
  end
end

def version_show
  @logger.info "BenchmarkBeholder"
  @logger.info "supported workloads: #{@hooks.join(", ")}"
  @logger.info "supported cloud platforms: oci"
  @logger.info "supported local filesystems: XFS, ext3/4, btrfs, and so forth"
  @logger.info "supported shared filesystems: GlusterFS, NFS, BeeGFS"
  @logger.info "supported special storage: raw block device, mdadm RAID, tmpfs, ramfs, brd, vboxsf"
  @logger.info "supported operating systems: Ubuntu, RHEL/CentOS, Fedora, Oracle Linux"
end

end

