module Metrics
  module_function

# In the `setup` method, you specify all the target metrics BBH should calculate for each combination of parameters
# Vector `v` refers to current combination of parameters
# You can refer to values of individual parameters by their names: `v.time`, `v.size`, etc, using the same parameter names as you defined in your workload file
# BBH will call `setup` just once, at startup, to define target metrics - that is, to know WHAT and HOW it should derive from the workload
# After that, BBH will launch the benchmarking and sweep `v` over all valid combinations of parameters
# NOTE: If you need pre-benchmark preparation, just place it in the beginning of `setup`
# NOTE: If you need preparation before EACH combination is benchmarked, define it as one more `func(:add, ...)` and call it from the function that invokes benchmark
def self.setup(space, logger, config, target)
  result = {} # here we'll store raw result of PING
  space.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
  space.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
  space.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time
  space.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f } # extract min ping time
  space.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f } # extract loss rate
end

end
