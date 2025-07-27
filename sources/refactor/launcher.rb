
class Launcher < FlexCartesian
  
def initialize(logger, config, target)
  super(config.parameters)
  @logger = logger
  @config = config
  @target = target
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
# TODO    Schedule.apply
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

  self.func(:add, :platform) { |v| @target.infra[v.host][:platform] }
  self.func(:add, :shape) { |v| @target.infra[v.host][:shape] }
  self.func(:add, :device) { |v| @target.infra[v.host][:device] }
  self.func(:add, :filesystem) { |v| @target.infra[v.host][:filesystem] }
  self.func(:add, :type) { |v| @target.infra[v.host][:type] }
  self.func(:add, :volumes) { |v| @target.infra[v.host][:volumes] }
end

end
