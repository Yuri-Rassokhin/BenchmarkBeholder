require 'tempfile'

module Metrics
  module_function

def setup(space, logger, config, target)
  result = ""

  space.func(:add, :command) do |v|
    case v.operation
      when "read"
        flow = "if=#{config.target} of=/dev/null"
      when "write"
        flow = "if=/dev/zero of=#{config.target}"
    end
    "#{config.actor} #{flow} bs=#{v.size} count=#{(config[:workload][:total_size]/v.size).to_i}".strip
  end

  space.func(:add, :result, hide: true) do |v|
    Global.run(binding, v.host, Scheduler.method(:switch), logger, v.scheduler, target.infra[v.host][:volumes])
    result = Global.run(binding, v.host, proc { `#{v.command} 2>&1>/dev/null`.strip })
  end

  space.func(:add, :error) do |v|
    `echo "#{result}" | grep error`.strip
  end

  space.func(:add, :bandwidth) do |v|
    bw = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $1}'`.strip.to_f
    units = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $2}'`.strip
    Utilities.convert_units(logger, bw, from: units, to: v.units, precision: config[:workload][:precision])
  end

  space.func(:add, :units) { config[:workload][:units] }

  # standard functions for infrastructure metrics
  Platform.add_infra(space: space, target: target, gpu: false)
end

end

