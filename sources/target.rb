class Target
  attr_reader :target, :protocol, :infra

def initialize(logger, config)
  @logger, @config, @hosts = logger, config, config.hosts

  if config.defined?(:workload, :protocol) and config.defined?(:workload, :target)
    @protocol, @target = config.protocol, config.target
    register # define all supported targets
    check(logger, config)
    @infra = infra_initialize
    @logger.info "target #{@protocol} #{@target} is healthy on benchmark nodes"
  else
    @protocol, @target = nil, nil
    @logger.warn "protocol + target pair isn't specified, skipping their tests"
  end
end

def supports_fs?
  [ "file", "directory", "ram" ].include?(@protocol)
end

def has_device?
  [ "file", "ram", "block" ].include?(@protocol)
end

def schedulers_apply?
  [ "file", "block" ].include?(@protocol)
end



private

def check(logger, config)
  logger.error "target protocol is not supported: #{@protocol}" unless protocol_supported?(@protocol)
  logger.error "target is missing" unless @target

  consistent_target

  if schedulers_apply?
    Scheduler.prepare(logger, config)
    logger.info "IO schedulers are consistent on benchmark nodes"
  end
end

def consistent_target
  @hosts.each do |h|
    unless Global.run(binding, h, File.method(:exist?), @target)
      @logger.error "target #{@protocol} #{@target} is missing on benchmark node #{h}"
      exit 0
    end
    case @protocol
      when "file"
        @logger.error "target '#{@target}' mismatch on '#{h}', regular file expected" unless Global.run(binding, h, File.method(:file?), @target)
        exit 0
      when "directory"
        @logger.error "target '#{@target}' mismatch on '#{h}', directory expected" unless Global.run(binding, h, File.method(:directory?), @target)
        exit 0
      when "block"
        @logger.error "target '#{@target}' mismatch on '#{h}', block device expected" unless Global.run(binding, h, File.method(:blockdev?), @target)
        exit 0
      when "ram", "gpu", "http", "cpu", "object", "bucket"
        @logger.warn "this target is NOT yet checked properly"
      else
        @logger.error "unsupported target: '#{File.stat(@config.target)}'"
        exit 0
      end
    end
end

def register
  @SUPPORTED = [
    { protocol: "file", description: "regular local file" },
    { protocol: "directory", description: "mount point" },
    { protocol: "gpu", description: "local GPU device(s)" },
    { protocol: "http", description: "HTTP server" },
    { protocol: "ram", description: "local RAM" },
    { protocol: "cpu", description: "local CPU(s)" },
    { protocol: "block", description: "local raw block device" },
    { protocol: "object", description: "single object in object storage" },
    { protocol: "bucket", description: "bucket of objects in object storage" }
  ]
end

def protocol_supported?(target_protocol)
  @SUPPORTED.each { |target| return true if target[:protocol] == target_protocol }
  false
end

def infra_initialize
  result = {}
  @hosts.each { |h| result[h] = Global.run(binding, h, Platform.method(:platform_collect), @logger, @config.target, has_device?) }
  result
end

end
