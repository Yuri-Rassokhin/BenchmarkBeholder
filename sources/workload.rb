require_relative './utilities'

class Workload < FlexCartesian
  attr_accessor :series

def initialize(logger: , config: )
  super config.sweep
  @logger = logger
  @config = config
  @workload_name = @config.workload
  @series = Time.now.to_i.to_s
  @result = {}
  @temp = {}
  @platform = nil
  @host = `hostname`.chomp
  load_metrics
  counter_set
  setup
end

def preparation
  prepare_path = "./sources/hooks/#{@workload_name}/prepare.rb"
  if File.exist?(prepare_path)
    require prepare_path
    load prepare_path
  end

  if self.class.private_instance_methods(false).include?(:prepare)
    @logger.info "running preparations for the benchmarking"
    prepare
  else
    @logger.info "nothing to prepare for the benchmarking"
  end
end

def benchmark
  @logger.info "starting workload #{@workload_name} series #{@series} on #{@host}"
  func(:run)
  @logger.info "completed workload #{@workload_name} series #{@series} on #{@host}"
end

def save
  report = "./log/bbh-#{@workload_name}-#{@series}-result.csv"
  FileUtils.mkdir_p(File.dirname(report))
  output(format: :csv, file: report)
end

private

def setup
  @logger.info "no metrics specified, nothing to do, exiting"
  exit 0
end

def load_metrics
  metrics_path = "./sources/hooks/#{@workload_name}/metrics.rb"
  @logger.error "incorrect integration of '#{@workload_name}', workload metrics '#{metrics_path}' are missing" unless File.exist?(metrics_path)
  require metrics_path
  load metrics_path
end

def eta
  eta_seconds = (@done == 0 ? "TBD" : (Time.now.to_i - @time_start).to_f/@done)
  @logger.human_readable_time(eta_seconds)
end

def log_invocation_start(v)
  res = <<~MSG
    *Workload* #{@workload_name}
    *Host* #{@host}
    *Series* #{@series}
    *Step* #{@counter}/#{@total} (#{@done}%)
    *ETA* #{eta}

    *Parameters*
    MSG
  res = res + "#{v.to_h.map { |k, v| "*#{k}* #{v}" }.join("\n")}"

  @logger.info!(res, :telegram)
  @logger.info!("╭ Step #{@counter}/#{@total} (#{@done}%) ETA #{eta} [ workload #{@workload_name} | host #{@host} | series #{@series} ]", :main)
  @logger.info!("│ Parameters [ #{dimensions(v, separator: " ")} ]", :main)
end

def log_invocation_done(v)
  res = <<~MSG
    *Workload* #{@workload_name}
    *Host* #{@host}
    *Series* #{@series}
    *Step* #{@counter}/#{@total} (#{@done}%)

    *Metrics*
  MSG
  @logger.info! res + "#{@result.map { |k, v| "*#{k}* #{v}" }.join("\n")}", :telegram
  @logger.info! "╰ Metrics [ #{@result.map { |k, v| "#{k}=#{v}" }.join(" ")} ]", :main
end

def counter_set
  @time_start = Time.now.to_i
  @counter = 0
  @total = self.size

  self.func(:add, :counter, hide: true, order: :first) do |v|
    @counter += 1
    @done = (@counter*100/@total.to_f).to_i
    log_invocation_start(v)
  end

  self.func(:add, :store, hide: true, order: :last) do |v|
    log_invocation_done(v)
    @result = {}
    @temp = {}
  end
end

end
