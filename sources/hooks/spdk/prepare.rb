class Workload

private

def prepare
  dir = @config[:misc][:spdk_dir]

  unless Etc.getpwuid(Process.uid).name == 'root' || system('sudo -n true')
    @logger.error "sudo access is required for system tuning"
    return
  end

  @logger.info "clearing up bdevperf instances"
  system("ps aux | grep '[b]devperf' | awk '{print $2}' | xargs -r sudo kill -9")

  @logger.info "setting memlock unlimited for root in limits.conf"
  limits_conf = "/etc/security/limits.conf"
  entry = "root hard memlock unlimited\nroot soft memlock unlimited"
  current = File.read(limits_conf) rescue ""
  unless current.include?("memlock unlimited")
    append = <<~LIMITS
      \n# added by BenchmarkBeholder
      root hard memlock unlimited
      root soft memlock unlimited
    LIMITS
    system("sudo bash -c 'echo \"#{append.strip}\" >> #{limits_conf}'")
    @logger.error "limits.conf updated, relogin will be required for change to take effect"
  end

  @logger.error "SPDK path #{dir} is missing, please clone and build https://github.com/spdk/spdk" unless Dir.exist?(dir)

  enabler = "#{dir}/scripts/setup.sh"
  @logger.error "SPDK enabler #{enabler} not found" unless File.exist?(enabler)
  @logger.info "enabling SPDK user space drivers"
  system("sudo #{enabler} 2>&1 > /dev/null")

  bdevperf = "#{dir}/build/examples/bdevperf"
  @logger.error "executable #{bdevperf} not found" unless File.exist?(bdevperf)

  hugepages = @config.misc[:hugepages]
  @logger.info "Setting #{hugepages} hugepages per NUMA node, please check if you've enough memory"
  Dir.glob('/sys/devices/system/node/node*/hugepages/hugepages-2048kB/nr_hugepages') do |path|
    system("sudo sh -c 'echo #{hugepages} > #{path}'")
  end

  @logger.info "Setting CPU governor to performance"
  Dir.glob('/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor') do |path|
    system("sudo sh -c 'echo performance > #{path} 2>&1 > /dev/null'")
  end

  drives = "#{dir}/#{@config.misc[:media]}"
  @logger.error "drives configuration file #{file} is missing" unless File.exist?(drives)
end

end
