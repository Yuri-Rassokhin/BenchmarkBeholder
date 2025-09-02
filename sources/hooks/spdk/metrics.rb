class Workload

private

def setup
  # built-in variables:
  # @temp - for storing data of the current combination; it is erased at the next combination
  # @result - for storing result of the current combination; it is logged, and the variable is erased
  # Note: all functions, except defined with hide: true, save results in the benchmarking report
  @temp = { command: nil, raw: nil, infra: nil }
  spdk_dir = "#{@config.startup[:spdk_dir]}"
  drives_conf = "#{spdk_dir}/#{@config.startup[:media]}"
  drives = JSON.generate(JSON.parse(File.read(drives_conf)))
  path = "#{spdk_dir}/build/examples"

  func(:add, :drives) { |v| @temp[:nvme_conf] ||= "\"#{drives}\"" }

  func(:add, :command) { |v| @temp[:command] ||= "sudo #{path}/bdevperf -c #{drives_conf} -q #{v.queue} -o #{v.size} -w #{v.operation} -t #{@config.startup[:time]} --lcores #{v.cores} 2>&1".strip }

  func(:add, :raw, hide: true) { |v| @temp[:raw] = `#{v.command}`.strip }

  func(:add, :bandwidth) { |v| @result[:bandwidth] ||= v.raw[/Total\s*:\s+([\d.]+)/, 1]&.to_f }

  func(:add, :bandwidth_units) { "MiB/s" }

  func(:add, :failures_per_sec) { |v| @result[:failures_per_sec] ||= v.raw[/Total\s*:\s+[\d.]+\s+[\d.]+\s+([\d.]+)/, 1]&.to_f }

  func(:add, :min_latency) { |v| @result[:min_latency] ||= v.raw[/Total\s*:\s+(?:[\d.]+\s+){5}([\d.]+)/, 1]&.to_f }

  func(:add, :max_latency) { |v| @result[:max_latency] ||= v.raw[/Total\s*:\s+(?:[\d.]+\s+){6}([\d.]+)/, 1]&.to_f }

  func(:add, :latency_units) { "us" }

  # standard functions for infrastructure metrics
  @temp[:infra] = {}
  Platform.metrics(logger: @logger, target: @config.target, space: self, result: @temp[:infra], gpu: false)
end

end
