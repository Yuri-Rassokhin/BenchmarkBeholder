class Launcher < FlexCartesian
  
def initialize(logger, config)
  super(config.parameters)
  @logger = logger
  @config = config
  setup
end

private

def setup
  result = ""

  self.func(:add, :command) do |v|
    case v.operation
      when "read", "randread"
        flow = "if=#{@config.target} of=/dev/null"
      when "write", "randwrite"
        flow = "if=/dev/zero of=#{@config.target}"
    end
    "#{@config.actor} #{flow} bs=#{v.size} count=#{v.count}".strip
  end

  self.func(:add, :result, hide: true) do |v|
    result = Global.run(binding, v.host, proc { `#{v.command} 2>&1>/dev/null`.strip })
  end

  self.func(:add, :error) do |v|
    `echo "#{result}" | grep error`.strip
  end

  self.func(:add, :bandwidth) do |v|
    `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $1}'`.strip.to_f
  end

  self.func(:add, :units) do |v|
    `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $2}'`.strip
  end
end

end
