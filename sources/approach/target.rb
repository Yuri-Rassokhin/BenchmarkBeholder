class Target
  attr_reader :target, :protocol

def initialize(logger, config)
  @logger = logger
  @protocol = config.protocol
  @target = config.target
  @hosts = config.hosts

  # nomenclature of all supported targets
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

  @logger.error "target protocol '#{@protocol}' is not supported" unless supported?(@protocol)
  @logger.error "target is missing" unless @target
  @logger.error "protocol '#{@protocol}' doesn't correspond to target '#{@target}'" unless check_target_type
  exist_everywhere?
  @logger.info "target #{@protocol}://#{@target} is healthy on all nodes"
end
   
def supports_fs?
  [ "file", "directory", "ram" ].include?(@protocol)
end

def has_device?
  [ "file", "ram", "block" ].include?(@protocol)
end

def exist_everywhere?
  case @protocol
  when "file", "directory", "block"
    @hosts.each { |h| logger.error "target '#{@target}' is missing on the node '#{h}'" unless Global.run(binding, h, File.method(:exist?), @target) }
    # TODO: check if FS is determined:   @logger.error("unsupported filesystem on '#{host}'") if supports_fs? and !@agent.run(host, :get_filesystem, @target)
    # TODO: check if 
  else
    puts "TODO: yet to implement"
  end
end

def io_schedulers_apply?
  [ "file", "block" ].include?(@protocol)
end



private

def supported?(target_protocol)
  @SUPPORTED.each { |target| return true if target[:protocol] == target_protocol }
  false
end

def check_target_type
  case @protocol
  when "file"
    File.file?(@target)
  when "directory"
    File.directory?(@target)
  when "block"
    File.blockdev?(@target)
  end
  true
end

end
