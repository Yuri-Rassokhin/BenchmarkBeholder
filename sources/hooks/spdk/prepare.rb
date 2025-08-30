class Workload

private

def prepare
  dir = @config[:misc][:spdk_dir]

  @logger.error "SPDK path #{dir} is missing, please clone and build https://github.com/spdk/spdk" unless Dir.exist?(dir)

  enabler = "#{dir}/scripts/setup.sh"
  @logger.error "SPDK enabler #{enabler} not found" unless File.exist?(enabler)
  @logger.info "enabling SPDK user space drivers"
  system("sudo #{enabler}")

  bdevperf = "#{dir}/build/examples/bdevperf"
  @logger.error "executable #{bdevperf} not found" unless File.exist?(bdevperf)

  @logger.info "Setting unlimited memlock (ulimit)"
  Process.setrlimit(Process::RLIMIT_MEMLOCK, Process::RLIM_INFINITY, Process::RLIM_INFINITY)

  hugepages = 32768
  @logger.info "Setting #{hugepages} hugepages per NUMA node, please check if you've enough memory"
  Dir.glob('/sys/devices/system/node/node*/hugepages/hugepages-2048kB/nr_hugepages') do |path|
    system("sudo sh -c 'echo 32768 > #{path}'")
  end

  @logger.info "Setting CPU governor to performance"
  Dir.glob('/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor') do |path|
    system("sudo sh -c 'echo performance > #{path}'")
  end

  drives = "#{dir}/#{@config.sweep[:media]}"
  @logger.error "drives configuration file #{file} is missing" unless File.exist?(drives)
end
