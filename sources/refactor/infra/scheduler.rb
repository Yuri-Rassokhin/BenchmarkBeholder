module Scheduler

def self.prepare(logger, config)
  conf_schedulers = Set.new(config.schedulers)
  config.hosts.each do |host|
    host_schedulers = Set.new(Global.run(binding, host, Scheduler.method(:schedulers)).split)
    diff = conf_schedulers ^ host_schedulers
    logger.error "IO scheduler(s) '#{diff.join(", ")}' differ from config on '#{host}'" unless diff.empty?

  end
end

def self.switch(logger, scheduler)
  #TODO
end

private

def self.schedulers
  `cat /sys/block/sda/queue/scheduler`.strip.gsub(/[\[\]]/, '')
end

end
