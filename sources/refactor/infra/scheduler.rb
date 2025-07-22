
module Schedule

def self.prepare(logger, target, config_schedulers)
  conf_schedulers = Set.new(config_schedulers)

  target.hosts.each do |host|
    host_schedulers = Set.new(Global.run(binding, host, :schedulers).split)
    diff = conf_schedulers ^ host_schedulers
    logger.error "IO scheduler(s) '#{diff.join(", ")}' differ from config on '#{host}'" unless diff == {}
  end
end

private

def self.schedulers
  `cat /sys/block/sda/queue/scheduler`.strip.gsub(/[\[\]]/, '')
end

end

