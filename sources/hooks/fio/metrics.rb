class Workload

private

def setup
  result = {}

  # NOTE: so far, indirect access is hardcoded for A). simplicity (to avoid validity checks with with ioengines, and B. practical need
  func(:add, :command) { |v| @result[:command] ||= "fio --direct=0 --unit_base=8 --kb_base=1024 --rw=#{v.operation} --bs=#{v.size} --ioengine=#{v.ioengine} --iodepth=#{v.iodepth} --runtime=15 --numjobs=#{v.processes} --time_based --group_reporting --name=bbh_fio --eta-newline=1 --filename=#{@config.target}".strip }

  func(:add, :result, hide: true) { |v| Scheduler.switch(@logger, v.scheduler, @platform.device[:volumes]); @result[:result] = `#{v.command}`.strip }

  func(:add, :iops) do |v|
    line = v.result.lines.select { |l| l.include?("iops") && l.include?("avg=") }.last
    res = line&.match(/avg=([\d.]+)/)&.captures&.first&.to_i || 0
    @result[:iops] ||= res
  end

  func(:add, :bandwidth) do |v|
    bw = v.result[/ \((\d+)kB\/s-/, 1].to_f
    res = Utilities.convert_units(@logger, bw, from: "KB/s", to: v.units, precision: @config[:misc][:precision])
    @result[:bandwidth] ||= res
    res
  end

  func(:add, :units) { @config[:workload][:units] }

  # standard functions for infrastructure metrics
  Platform.metrics(logger: @logger, target: @config[:misc][:target], space: self, gpu: false)
end

end

