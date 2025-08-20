module Scheduler

def self.prepare(logger, config)
  conf_schedulers = Set.new(config.schedulers)
  config.hosts.each do |host|
    host_schedulers = Set.new(Global.run(binding, host, Scheduler.method(:schedulers)).split)
    diff = conf_schedulers ^ host_schedulers
    logger.warn "IO scheduler(s) '#{diff.join(", ")}' differ from config on '#{host}'" unless diff.empty?

  end
end

def self.switch(logger, scheduler, volumes)
  @target.infra[v.host][:volumes]
  volumes.each do |v|
    begin
      `sudo bash -c "echo #{scheduler} > /sys/block/#{base_device(v)}/queue/scheduler"`
    rescue => e
      logger.error("Failed to switch IO scheduler for #{v}: #{e.message}")
    end
  end
end

private

def self.base_device(dev_path)
  dev = File.basename(dev_path)
  output = `lsblk -no PKNAME /dev/#{dev}`.lines.first&.strip
  output.empty? ? dev : output
end

def self.schedulers
  `cat /sys/block/sda/queue/scheduler`.strip.gsub(/[\[\]]/, '')
end

end
