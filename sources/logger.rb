class CustomLogger
  SEVERITY_LEVELS = {
    debug: 1,
    info: 2,
    warn: 3,
    fail: 4,
    fatal: 5
  }

  def initialize(series, min_level = :debug)
    @min_level = SEVERITY_LEVELS[min_level]
    unless @min_level
      raise ArgumentError, "Invalid minimum severity level: #{min_level}"
    end
    @flag_warn = false

    #create log directories
    @log_dir = "bbh-#{series}"
    tmp_dir = "/tmp/bbh/#{@log_dir}"
    FileUtils.mkdir_p(tmp_dir)
    @warning_log = Tempfile.new(['warning', '.log'], tmp_dir)
    @warning_log = File.open(@warning_log.path, 'a')
  end

  def debug(message)
    log(:debug, message)
  end

  def info(message)
    log(:info, message)
  end

  def warning(message)
    log(:warn, message)
    @flag_warn = true
  end

  def error(message)
    log(:fail, message)
  end

  def fatal(message)
    log(:fatal, message)
  end

  def note(message)
    print "%-55s" % "Checking #{message}"
    yield
    puts @flag_warn ? "[WARN]" : "[ OK ]"
  end

  private

  def log(severity, message)
    current_level = SEVERITY_LEVELS[severity]
    if current_level.nil?
      file, line = caller_locations(1,1)[0].path, caller_locations(1,1)[0].lineno
      puts "[FATAL] Invalid severity level: #{severity} at #{file}:#{line}"
    end

    if current_level >= @min_level
      file, line = caller_locations(2,1)[0].path, caller_locations(2,1)[0].lineno
      print "[#{severity.upcase}] #{message}"
      puts current_level == SEVERITY_LEVELS[:debug] ? "at #{file}:#{line}" : ""
    end

    exit 1 if SEVERITY_LEVELS[severity] > SEVERITY_LEVELS[:warn]
  end

end

