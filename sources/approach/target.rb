class Target
  attr_reader :target, :protocol

def initialize(logger, config)
  @logger, @protocol, @target, @hosts = logger, config.protocol, config.target, config.hosts
  register # define all supported targets
  check
  @logger.info "target #{@protocol} '#{@target}' is healthy on all nodes"
end

# TODO
def supports_fs?
  [ "file", "directory", "ram" ].include?(@protocol)
end

# TODO
def has_device?
  [ "file", "ram", "block" ].include?(@protocol)
end

def schedulers_apply?
  [ "file", "block" ].include?(@protocol)
end



private

def check
  @logger.error "target protocol '#{@protocol}' is not supported" unless protocol_supported?(@protocol)
  @logger.error "target is missing" unless @target

  consistent_target

  if schedulers_apply?
    Schedule.prepare(logger, target, config.schedulers)
    @logger.info "IO schedulers are consistent on all nodes"
  end
end

def consistent_target
  @hosts.each do |h|
    case @protocol
      when "file"
        @logger.error "target '#{@target}' mismatch on '#{h}', regular file expected" unless Global.run(binding, h, File.method(:exist?), @target)
      when "directory"
        @logger.error "target '#{@target}' mismatch on '#{h}', directory expected" unless Global.run(binding, h, File.method(:directory?), @target)
      when "block"
        @logger.error "target '#{@target}' mismatch on '#{h}', block device expected" unless Global.run(binding, h, File.method(:blockdev?), @target)
      when "ram", "gpu", "http", "cpu", "object", "bucket"
        @logger.warn "this target is NOT yet checked properly"
      else
        @logger.error "unsupported target: '#{File.stat(@config.target)}'"
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

end
