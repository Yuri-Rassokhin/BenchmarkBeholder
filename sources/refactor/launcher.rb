
class Launcher < FlexCartesian
  
def initialize(logger, config, target)
  super(config.parameters.merge!({ iteration: (1..config[:workload][:iterations]).to_a}))
  @logger = logger
  @config = config
  @target = target
  setup
end

private

def convert_to_gbps(bandwidth, units)
  case units
  when "kB/s"
    bandwidth = bandwidth / 1024 / 1024
  when "MB/s"
    bandwidth = bandwidth / 1024
  when "GB/s"
    bandwidth = bandwidth
  when "TB/s"
    bandwidth = bandwidth * 1024
  when "PB/s"
    bandwidth = bandwidth * 1024 * 1024
  else
    @logger.error "unsupported units #{units}"
  end
  bandwidth.round(4)
end

def puts_dimensions(obj)
  return obj.inspect unless obj.is_a?(Struct)
  obj.each_pair.map { |k, v| "#{k}=#{v}" }.join(', ')
end

def setup
  result = ""
  counter = 1
  total = self.size

  self.func(:add, :command) do |v|
    @logger.info "invocation #{counter} of #{total}: #{puts_dimensions(v)}"
    case v.operation
      when "read"
        flow = "if=#{@config.target} of=/dev/null"
      when "write"
        flow = "if=/dev/zero of=#{@config.target}"
    end
    "#{@config.actor} #{flow} bs=#{v.size} count=#{(@config[:workload][:total_size]/v.size).to_i}".strip
  end

  self.func(:add, :result, hide: true) do |v|
    Scheduler.switch(@logger, v.scheduler, @target.infra[v.host][:volumes])
    result = Global.run(binding, v.host, proc { `#{v.command} 2>&1>/dev/null`.strip })
    counter += 1
  end

  self.func(:add, :error) do |v|
    `echo "#{result}" | grep error`.strip
  end

  self.func(:add, :bandwidth) do |v|
    bw = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $1}'`.strip.to_f
    units = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $2}'`.strip
    convert_to_gbps(bw, units)
  end

  self.func(:add, :units) do |v|
    "GB/s"
  end

  self.func(:add, :platform) { |v| @target.infra[v.host][:platform] }
  self.func(:add, :shape) { |v| @target.infra[v.host][:shape] }
  self.func(:add, :device) { |v| @target.infra[v.host][:device] }
  self.func(:add, :fs) { |v| @target.infra[v.host][:filesystem] }
  self.func(:add, :fs_block_size) { |v| @target.infra[v.host][:filesystem_block_size] }
  self.func(:add, :fs_mount_options) { |v| @target.infra[v.host][:filesystem_mount_options] }
  self.func(:add, :type) { |v| @target.infra[v.host][:type] }
  self.func(:add, :volumes) { |v| @target.infra[v.host][:volumes] }
  self.func(:add, :kernel) { |v| @target.infra[v.host][:kernel] }
  self.func(:add, :os_release) { |v| @target.infra[v.host][:os_release] }
  self.func(:add, :arch) { |v| @target.infra[v.host][:arch] }
  self.func(:add, :cpu) { |v| @target.infra[v.host][:cpu] }
  self.func(:add, :cores) { |v| @target.infra[v.host][:cores] }
  self.func(:add, :cpu_ram) { |v| @target.infra[v.host][:cpu_ram] }
end

end
