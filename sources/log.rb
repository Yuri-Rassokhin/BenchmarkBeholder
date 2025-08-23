class Log
  def initialize
    @logger = logger_initialize
    telegram_data = telegram_initialize
    @telegram_token = telegram_data[:token]
    @telegram_chat_id = telegram_data[:chat_id]
  end

  # generates raw message without modifications
  # streams: :telegram, :main, or both by default
  def info!(text, stream = nil)
    @logger.info(text) unless stream == :telegram
    telegram_message(:info, text) unless stream == :main
  end

  def info(msg, stream = nil)
    info!(msg[0].upcase + msg[1..], stream)
  end

  def warn(msg)
    text = msg[0].upcase + msg[1..]
    @logger.warn(text)
    telegram_message(:warn, text)
  end

  def error(msg)
    text = msg[0].upcase + msg[1..]
    @logger.error(text)
    telegram_message(:error, text)
    exit 1
  end

  def human_readable_time(seconds)
    days = (seconds / (24 * 3600)).to_i
    hours = (seconds % (24 * 3600) / 3600).to_i
    minutes = (seconds % 3600 / 60).to_i
    readable = []
    readable << "#{days}d" if days > 0
    readable << "#{hours}h" if hours > 0
    readable << "#{minutes}m" if minutes > 1
    readable << "#{minutes}m" if minutes == 1
    readable.empty? ? "<1m" : readable.join(" ")
  end

  private

  def telegram_initialize
    token_file = File.expand_path("~/.bbh/telegram")

    unless File.exist?(token_file)
      @logger.warn("telegram token is not specified, there will be no telegram logging")
      return { token: nil, chat_id: nil }
    end

    token = File.read(token_file).chomp
    uri = URI("https://api.telegram.org/bot#{token}/getUpdates")
    response = Net::HTTP.get(uri)
    updates = JSON.parse(response)

    if updates["result"] == []
      @logger.error("telegram bot has gone asleep, please send something to it and rerun the benchmark")
      exit 0
    elsif updates["result"] == nil
      @logger.error("telegram bot not found, please check correctness of the token #{token_file}")
    end

    updates["result"].each do |update|
      return { token: token, chat_id: update['message']['chat']['id'] }
    end

    { token: nil, chat_id: nil }
  end

    SEVERITY_MAP = {
      "DEBUG"   => "D",
      "INFO"    => "I",
      "WARN"    => "W",
      "ERROR"   => "E",
      "FATAL"   => "F",
      "UNKNOWN" => "U"
    }

  def logger_initialize
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    logger.formatter = proc do |severity, datetime, progname, msg|
      severity_letter = SEVERITY_MAP[severity] || severity[0]
      "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity_letter} #{msg}\n"
    end
    logger
  end

  def telegram_message(level, text)
    return unless @telegram_token && @telegram_chat_id

    uri = URI("https://api.telegram.org/bot#{@telegram_token}/sendMessage")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = {
      chat_id: @telegram_chat_id,
      text: telegram_format(level, text),
      parse_mode: "MarkdownV2"
    }.to_json

    http.request(request)
  rescue StandardError => e
    @logger.error("failed to send telegram chat message: #{e.message}")
  end

def telegram_format(level, msg)
  res = msg.gsub(/([_\[\]()~`>#+\-=|{}.!\\])/, '\\\\\1')
  case level
  when :warn
    tmp = <<~MSG
    *WARNING*
    MSG
    res = tmp + res
  when :error
    tmp = <<~MSG
    *ERROR*
    MSG
    res = tmp + res
  end
  res
end

end

