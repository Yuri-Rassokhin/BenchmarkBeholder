module Scheduler

def self.prepare(logger, config)
  conf_schedulers = Set.new(config.schedulers)
  host_schedulers = Set.new(Scheduler.schedulers.split)
  diff = conf_schedulers ^ host_schedulers
  logger.warn "IO schedulers #{diff.join(", ")} are not in sweep file" unless diff.empty?
  end
end

def self.switch(logger, scheduler, volumes)
  @target.infra[v.host][:volumes]
  volumes.each do |v|
    begin
      `sudo bash -c "echo #{scheduler} > /sys/block/#{base_device(v)}/queue/scheduler"`
    rescue => e
      logger.error("failed to switch IO scheduler for #{v}: #{e.message}")
    end
  end
end

class << self
private

def base_device(dev_path)
  dev = File.basename(dev_path)
  output = `lsblk -no PKNAME /dev/#{dev}`.lines.first&.strip
  output.empty? ? dev : output
end

def schedulers
  `cat /sys/block/sda/queue/scheduler`.strip.gsub(/[\[\]]/, '')
end

end
