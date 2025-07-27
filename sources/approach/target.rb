require_relative '../refactor/infra/scheduler'
require_relative '../refactor/infra/platform'

class Target
  attr_reader :target, :protocol, :infra

def initialize(logger, config)
  @config, @logger, @protocol, @target, @hosts = config, logger, config.protocol, config.target, config.hosts
  register # define all supported targets
  check(logger, config)
  @infra = infra_initialize
  @logger.info "target #{@protocol} '#{@target}' is healthy on all nodes"
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
  logger.error "target protocol '#{@protocol}' is not supported" unless protocol_supported?(@protocol)
  logger.error "target is missing" unless @target

  consistent_target

  if schedulers_apply?
    Scheduler.prepare(logger, config)
    logger.info "IO schedulers are consistent on all nodes"
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

def infra_initialize
  result = {}
  @hosts.each { |h| result[h] = Global.run(binding, h, Platform.method(:platform_collect), @config.target, has_device?) }
  result
end

end
