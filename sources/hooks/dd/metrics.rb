require 'tempfile'

module Metrics
  module_function

def file_init
  size = @config[:workload][:total_size]
  file = @target.target

  @logger.info "creating target file #{file} of the size #{size}, rounded to megabytes"
  File.open(file, "wb") do |f|
      block = "\0" * 1024 * 1024  # 1MB
      (size / block.size).times { f.write(block) }
  end
end

def setup(space, logger, config)
  file_init

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
    Global.run(binding, Scheduler.method(:switch), @logger, v.scheduler, @target.infra[v.host][:volumes])
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

