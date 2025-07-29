require_relative './utilities'

class Launcher < FlexCartesian
  
def initialize(logger, config, target)
  super(config.parameters.merge!({ iteration: (1..config[:workload][:iterations]).to_a}))
  @logger = logger
  @config = config
  @target = target
  @counter = 0
  @total = self.size
  prepare
  setup
end

private

def prepare
  self.func(:add, :counter, hide: true) do |v|
    @counter += 1
    @logger.info "invocation #{@counter} of #{@total}: #{self.dimensions(v, separator: ' ')}"
  end
end

def setup
  result = ""

  self.func(:add, :command) do |v|
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
  end

  self.func(:add, :error) do |v|
    `echo "#{result}" | grep error`.strip
  end

  self.func(:add, :bandwidth) do |v|
    bw = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $1}'`.strip.to_f
    units = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $2}'`.strip
    Utilities.convert_units(@logger, bw, from: units, to: v.units, precision: @config[:workload][:precision])
  end

  self.func(:add, :units) { @config[:workload][:units] }

  self.func(:add, :platform) { |v| @target.infra[v.host][:platform] }
  self.func(:add, :shape) { |v| @target.infra[v.host][:shape] }
  self.func(:add, :device) { |v| @target.infra[v.host][:device] }
  self.func(:add, :fs) { |v| @target.infra[v.host][:filesystem] }
  self.func(:add, :fs_block_size) { |v| @target.infra[v.host][:filesystem_block_size] }
  self.func(:add, :fs_mount_options) { |v| "\"#{@target.infra[v.host][:filesystem_mount_options]}\"" }
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
