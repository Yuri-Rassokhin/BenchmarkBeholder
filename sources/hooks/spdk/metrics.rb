class Workload

private

def setup
  # built-in variables:
  # @temp - for storing data of the current combination; it is erased at the next combination
  # @result - for storing result of the current combination; it is logged, and the variable is erased
  #
  # Note: all functions, except defined with hide: true, save results in the benchmarking report
  @temp = { command: nil, raw: nil, infra: nil }

  spdk_dir = "#{@config[:misc][:spdk_dir]}"
  path = "#{spdk_dir}/build/examples"

  # NOTE: so far, indirect access is hardcoded for A). simplicity (to avoid validity checks with with ioengines, and B. practical need
  func(:add, :command) { |v| @temp[:command] ||= "sudo #{path}/bdevperf -c #{spdk_dir}/#{v.media} -q #{v.queue} -o #{v.size} -w #{v.operation} -t 30 --lcores #{v.cores}".strip }

  func(:add, :raw, hide: true) { |v| @temp[:raw] = `#{v.command}`.strip }

  func(:add, :iops) { |v| @result[:iops] ||= JSON.parse(v.raw)["jobs"][0][v.operation]["iops"].to_i }

  # BW converted to MB/s
  func(:add, :bandwidth) { |v| @result[:bandwidth] ||= JSON.parse(v.raw)["jobs"][0][v.operation]["bw_bytes"].to_f / 1_000_000 }

  func(:add, :units) { "MB/s" }

  # standard functions for infrastructure metrics
  @temp[:infra] = {}
  Platform.metrics(logger: @logger, target: @config.target, space: self, result: @temp[:infra], gpu: false)
end

end
