class Workload

private

def setup
  result = {}

  # NOTE: so far, indirect access is hardcoded for A). simplicity (to avoid validity checks with with ioengines, and B. practical need
  func(:add, :command) { |v| @result[:command] ||= "fio --direct=0 --rw=#{v.operation} --bs=#{v.size} --ioengine=#{v.ioengine} --iodepth=#{v.iodepth} --output-format=json --runtime=15 --numjobs=#{v.processes} --time_based --name=bbh_fio --filename=#{@config.target}".strip }

  func(:add, :result, hide: true) { |v| Scheduler.switch(@logger, v.scheduler, @volumes); @result[:result] = `#{v.command}`.strip }

  # TODO!!! operation "read" can be different...
  func(:add, :iops) { |v| @result[:iops] ||= JSON.parse(v.result)["jobs"][0]["read"]["iops"].to_i }

  # BW converted to MB/s
  func(:add, :bandwidth) { |v| @result[:bandwidth] ||= JSON.parse(v.result)["jobs"][0]["read"]["bw_bytes"].to_f / 1_000_000 }

  func(:add, :units) { "MB/s" }

  # standard functions for infrastructure metrics
#  Platform.metrics(logger: @logger, target: @config[:misc][:target], space: self, gpu: false)
end

end

