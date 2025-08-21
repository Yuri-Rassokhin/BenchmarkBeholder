class Workload

private

# In the `setup` method, you specify all the target metrics BBH should calculate for each combination of parameters
# Vector `v` refers to current combination of parameters
# You can refer to values of individual parameters by their names: `v.time`, `v.size`, etc, using the same parameter names as you defined in your workload file
# BBH will call `setup` just once, at startup, to define target metrics - that is, to know WHAT and HOW it should derive from the workload
# After that, BBH will launch the benchmarking and sweep `v` over all valid combinations of parameters
# NOTE: If you need pre-benchmark preparation, just place it in the beginning of `setup`
# NOTE: If you need preparation before EACH combination is benchmarked, define it as one more `func(:add, ...)` and call it from the function that invokes benchmark
def setup
  self.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
  self.func(:add, :raw_ping, hide: true) { |v| @result[:raw] ||= `#{v.command} 2>&1` } # run PING and save its raw result
  self.func(:add, :time) { |v| @result[:time] ||= v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f }
  self.func(:add, :min) { |v| @result[:min] ||= v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f }
  self.func(:add, :loss) { |v| @result[:loss] ||= v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f }
end

end
