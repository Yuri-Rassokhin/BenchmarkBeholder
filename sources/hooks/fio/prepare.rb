class Target

def prepare(logger, config)
  size = config[:workload][:total_size]
  file = config.target

  logger.info "creating target file #{file} of the size #{size}, rounded to megabytes"
  File.open(file, "wb") do |f|
      block = "\0" * 1024 * 1024  # 1MB
      (size / block.size).times { f.write(block) }
  end
end

end
