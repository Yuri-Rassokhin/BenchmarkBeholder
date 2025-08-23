class Workload

private

def setup
  # NOTE: so far, indirect access is hardcoded for A). simplicity (to avoid validity checks with with ioengines, and B. practical need
  func(:add, :command) { |v| @temp[:command] ||= "fio --direct=0 --rw=#{v.operation} --bs=#{v.size} --ioengine=#{v.ioengine} --iodepth=#{v.iodepth} --output-format=json --numjobs=#{v.processes} --name=bbh_fio --filename=#{@config.target}".strip }

  func(:add, :raw, hide: true) { |v| Scheduler.switch(@logger, v.scheduler, @volumes); @temp[:raw] = `#{v.command}`.strip }

  func(:add, :iops) { |v| @result[:iops] ||= JSON.parse(v.raw)["jobs"][0][v.operation]["iops"].to_i }

  # BW converted to MB/s
  func(:add, :bandwidth) { |v| @result[:bandwidth] ||= JSON.parse(v.raw)["jobs"][0][v.operation]["bw_bytes"].to_f / 1_000_000 }

  func(:add, :units) { "MB/s" }

  # standard functions for infrastructure metrics
  @temp[:infra] = {}
  Platform.metrics(logger: @logger, target: @config.target, space: self, result: @temp[:infra], gpu: false)
end

end
