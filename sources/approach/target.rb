class Target

def initialize(target, health = nil)

  # store the entire target
  @target = target

  # nomenclature of all supported targets
  @SUPPORTED = [
    { type: "file", description: "regular local file" },
    { type: "mount", description: "mount point" },
    { type: "gpu", description: "local GPU device(s)" },
    { type: "http", description: "HTTP server" },
    { type: "ram", description: "local RAM" },
    { type: "cpu", description: "local CPU(s)" },
    { type: "block", description: "local raw block device" },
    { type: "object", description: "a single object in object storage" },
    { type: "bucket", description: "a bucket of objects in object storage" }
  ]

  # determine type of the target
  @type = type(target)
  raise "target type '#{@type}' is not supported" unless supported?(@type)

  # determine path to the target
  @path = path(target)
  raise "target path is undefined" unless @path

end

def output_supported
  @SUPPORTED.each |type, description| do
    puts "#{type}://   #{description.uppercase}"
  end
end

def supports_fs?
  [ "file", "mount point", "cpu ram" ].include?(@type)
end

def has_device?(target_type)
  [ "file", "device", "cpu ram" ].include?(@type)
end

def available?(target_health)
  `curl -o /dev/null -s -w "%{http_code}" #{target_health}` == "200"
end

private

def type(target)
  type = target[/\A(\w+):\/\//, 1]

end

def path(target)
  target[/\A\w+:\/\/(.*)/, 1]
end

def supported?(target_type)
  @SUPPORTED.each |type, description| do
    return true if type == target_type
  end
  false
end

end
