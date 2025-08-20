class Target
  attr_reader :protocol, :target, :infra

  def initialize(logger: , protocol: , id: , :hook )
  @logger, @protocol, @id, @hook = logger, protocol, id, hook

  prepare_target

  register # define all supported targets
  check(logger, config)
  @infra = infra_initialize
  @logger.info "target #{@protocol} #{@id} is healthy on benchmark nodes"
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

def prepare_target
  prep_file = "./sources/hooks/#{@hook}/prepare"
  if File.exist?(prep_file)
    @logger.info "preparing target '#{@protocol}://#{@id}' "
    require_relative prep_file if File.exist?(prep_file)
    prepare(@logger, @config)
  end)
end

def check(logger, config)
  logger.error "target protocol is not supported: #{@protocol}" unless protocol_supported?(@protocol)
  logger.error "target is missing" unless @id

  if schedulers_apply?
    Scheduler.prepare(logger, config)
    logger.info "IO schedulers are consistent on benchmark nodes"
  end
end

def consistent_target?
  @hosts.each do |h|

    unless Global.run(binding, h, File.method(:exist?), @target)
      @logger.error "target #{@protocol} #{@target} is missing on benchmark node #{h}"
      return false
    end

    case Global.run(binding, h, proc { File.stat.ftype }, @target).file?
    when "Regular file"
      @logger.error "target #{@target} mismatch on #{h}: file expected" unless @protocol == "file"
      return false
    when "Directory"
      @logger.error "target #{@target} mismatch on #{h}, directory expected" unless @protocol == "directory"
      return false
    when "Block device"
      @logger.error "target #{@target} mismatch on #{h}, block device expected" unless @protocol == "block"
      return false
# TODO: check against "ram", "gpu", "http", "cpu", "object", "bucket"
    else
      @logger.error "unsupported target: #{File.stat(@target)}"
      return false
    end
  end
  return true
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
