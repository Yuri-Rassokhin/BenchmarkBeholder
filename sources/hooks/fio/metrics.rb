require 'tempfile'

module Metrics
  module_function

def setup(space, logger, config, target)
  result = {}

  space.func(:add, :command) do |v|
    "#{config.actor} --direct=#{v.direct} --unit_base=8 --kb_base=1024 --rw=#{v.operation} --bs=#{v.size} --ioengine=#{v.ioengine} --iodepth=#{v.iodepth} --runtime=15 --numjobs=#{v.processes} --time_based --group_reporting --name=bbh_fio --eta-newline=1 --filename=#{config.target}".strip
  end

  space.func(:add, :result, hide: true) do |v|
    Global.run(binding, v.host, Scheduler.method(:switch), logger, v.scheduler, target.infra[v.host][:volumes])
    result[v.command] ||= Global.run(binding, v.host, proc { `#{v.command}`.strip })
    result[v.command]
  end

  space.func(:add, :iops) do |v|
    line = v.result.lines.select { |l| l.include?("iops") && l.include?("avg=") }.last
    line&.match(/avg=([\d.]+)/)&.captures&.first&.to_f || 0.0
  end

  space.func(:add, :bandwidth) do |v|
    bw = v.result[/ \((\d+)kB\/s-/, 1].to_f
    Utilities.convert_units(logger, bw, from: "KB/s", to: v.units, precision: config[:workload][:precision])
  end

  space.func(:add, :units) { config[:workload][:units] }

  # standard functions for infrastructure metrics
  Platform.add_infra(space: space, target: target, gpu: false)
end

end

