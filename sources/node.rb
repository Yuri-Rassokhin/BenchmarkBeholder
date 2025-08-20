module Node
@logger, @config, @workload = nil, nil, nil

def self.check(logger: , config: )
  @logger, @config = logger, config
  check_another_instance
  check_dependencies
  check_cpu_idle
  check_storage_idle
end

class << self
private

def check_another_instance
  @logger.info "checking if another BBH instance is running"
  lockfile_path = "/tmp/bbh.lock"
  lockfile = File.open(lockfile_path, File::RDWR|File::CREAT, 0644)
  unless lockfile.flock(File::LOCK_NB | File::LOCK_EX)
    @logger.error "another BBH instance is already running, exiting"
    exit 1
  end
end

def check_dependencies
  @logger.info "checking dependencies"
  [ "ruby", "curl", "mpstat", "iostat" ].each do |tool|
    unless Utilities.file_exists?("#{tool}")
      @logger.error("'#{tool}' is missing, please install it")
    end
  end
end

def check_cpu_idle
  @logger.info "checking if CPU cores are idle"
  @logger.error("CPU utilization >= 10%, no good for benchmarking") if cpu_idle < 90
end

def check_storage_idle
  @logger.info "checking if IO subsystem is idle"
  @logger.error("IO utilization >= 10%, no good for benchmarking") if io_idle < 90
end

end
end
