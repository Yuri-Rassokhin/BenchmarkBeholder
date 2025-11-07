module Scheduler

def self.prepare(logger, config)
  conf_schedulers = Set.new(config[:sweep][:scheduler])
  host_schedulers = Set.new(schedulers.split)
  diff = conf_schedulers ^ host_schedulers
  logger.warn "IO scheduler(s) #{diff.join(", ")} not in workload file" unless diff.empty?
end

def self.switch(logger, scheduler, volumes)
  volumes.each do |v|
    begin
      `sudo bash -c "echo #{scheduler} > /sys/block/#{base_device(v)}/queue/scheduler"`
    rescue => e
      logger.error("failed to switch IO scheduler for #{v}: #{e.message}")
    end
  end
end

def self.base_device(dev_path)
  dev = File.basename(dev_path)
  output = `lsblk -no PKNAME /dev/#{dev}`.lines.first&.strip
  output.empty? ? dev : output
end

def self.schedulers
  `cat /sys/block/sda/queue/scheduler`.strip.gsub(/[\[\]]/, '')
end

end
