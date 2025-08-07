class Metrics < Hook

def initialize(logger, config, target)
  super(logger, config, target)
end

private

# In .setup, we specify what BBH should do for each combination of parameters, vector `v`
# `v` sweeps over all combinations of values specified in `parameters` section of the workload file
# This method is called just once and sets WHAT and HOW to benchmark.
# (If you need to arrange any one-time preparations before the benchnarking, you can do it from .setup
# However, if you need preparations before EACH combination is benchmarked, you should define it as a function below)
def setup
  result = {} # here we'll store raw result of PING
  func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
  func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
  func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time from result
  func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f } # extract min ping time from result
  func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f } # extract loss rate from result
end

end

