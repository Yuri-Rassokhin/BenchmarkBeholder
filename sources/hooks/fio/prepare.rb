class Workload

private

def prepare
  size = @config[:misc][:total_size]
  file = @config.target

  @logger.error "command fio not found in the system" if `command -v fio`.empty?

  Scheduler.prepare(@logger, @config)

  @volumes = Platform.scan_device(file)[:volumes]

  @logger.info "creating target file #{file} of the size #{size}, rounded to megabytes"
  File.open(file, "wb") do |f|
      block = "\0" * 1024 * 1024  # 1MB
      (size / block.size).times { f.write(block) }
  end
end

end
