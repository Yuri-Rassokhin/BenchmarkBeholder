class Target
  attr_reader :name, :protocol, :path

def initialize(agent, logger, target, health = nil)

  @agent = agent

  @logger = logger

  # store the entire target
  @name = target

  # nomenclature of all supported targets
  @SUPPORTED = [
    { protocol: "file", description: "regular local file" },
    { protocol: "mount", description: "mount point" },
    { protocol: "gpu", description: "local GPU device(s)" },
    { protocol: "http", description: "HTTP server" },
    { protocol: "ram", description: "local RAM" },
    { protocol: "cpu", description: "local CPU(s)" },
    { protocol: "block", description: "local raw block device" },
    { protocol: "object", description: "a single object in object storage" },
    { protocol: "bucket", description: "a bucket of objects in object storage" }
  ]

  # determine protocol of the target
  @protocol = protocol_get(target)
  logger.error "protocol is missing for the target '#{@name}'" unless @protocol
  logger.error "target protocol '#{@protocol}' is not supported" unless supported?(@protocol)

  # determine path to the target
  @path = path_get(target)
  logger.error "target path is undefined" unless @path
end

def output_supported
  @SUPPORTED.each { |target| puts "#{target[:protocol]}://   #{target[:description].uppercase}" }
end

def supports_fs?
  [ "file", "mount", "ram" ].include?(@protocol)
end

def has_device?
  [ "file", "ram", "block" ].include?(@protocol)
end

def available?(host)
  case @protocol
  when "file" then @agent.run(host, :file_exists?, @path)
  when "block" then @agent.run(host, :block_device_exists?, @path)
  when "http" then true
  when "bucket" then @agent.run(host, :oci_bucket_exists?, @path)
  when "object" then @agent.run(host, :oci_object_exists?, @path)
  else logger.error "unknown target protocol '#{@protocol}'"
  end
#    `curl -o /dev/null -s -w "%{http_code}" #{target_health}` == "200"
end

# run all the target checks on a given node
def check(host)

  # check if the target is available from the host
  logger.error("target '#{@name}' is unavailable on '#{host}'") if !available?(host)

  # check if the target supports filesystem, and we can determine the filesystem
  logger.error("unsupported filesystem on '#{host}'") if supports_fs? and !@agent.run(host, :get_filesystem, @path)
end

def io_schedulers_apply?
  [ "file", "block" ].include?(@protocol)
end

private

def protocol_get(target)
  target[/\A(\w+):\/\//, 1]
end

def path_get(target)
  target[/\A\w+:\/\/(.*)/, 1]
end

def supported?(target_protocol)
  @SUPPORTED.each { |target| return true if target[:protocol] == target_protocol }
  false
end

end
