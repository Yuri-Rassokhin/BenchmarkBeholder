class Log
  def initialize
    @logger = logger_initialize
    telegram_data = telegram_initialize
    @telegram_token = telegram_data[:token]
    @telegram_chat_id = telegram_data[:chat_id]
    @in_group = false
  end

  # this is the basic method for logging
  # generates raw message without modifications
  # streams: :telegram, :main, or both by default
  def info!(text, stream: nil, file: nil, group: nil)
    res = group_prefix(text, group: group)
    @logger.info(res) unless stream == :telegram
    telegram_message(:info, text, file: file) unless stream == :main
  end

  def info(msg, stream: nil, file: nil, group: nil)
    info!(msg[0].upcase + msg[1..], stream: stream, file: file, group: group)
  end

  def warn(msg, group: nil)
    text = msg[0].upcase + msg[1..]
    res = group_prefix(text, group: group)
    res = yellow(res)
    @logger.warn(res)
    telegram_message(:warn, text)
  end

  def error(msg, group: nil)
    text = msg[0].upcase + msg[1..]
    res = group_prefix(text, group: group)
    res = red(res)
    @logger.error(res)
    telegram_message(:error, text)
    exit 1
  end

  def human_readable_time(seconds)

    def numeric?(seconds)
      true if Float(seconds) rescue false
    end

    return seconds unless numeric?(seconds)

    days = (seconds / (24 * 3600)).to_i
    hours = (seconds % (24 * 3600) / 3600).to_i
    minutes = (seconds % 3600 / 60).to_i
    readable = []
    readable << "#{days}d" if days > 0
    readable << "#{hours}h" if hours > 0
    readable << "#{minutes}m" if minutes > 1
    readable << "#{minutes}m" if minutes == 1
    readable.empty? ? "<1m" : readable.join(":")
  end

  private

  def yellow(text)
    "\e[33m#{text}\e[0m"
  end

  def red(text)
    "\e[31m#{text}\e[0m"
  end

  def group_prefix(text, group: nil)
    # close group
    if group == false and @in_group
      @in_group = false
      return "╰ #{text}"
    end

    # open group
    if group == true and not @in_group
      @in_group = true
      return "\e[1m╭ #{text}\e[0m"
    end

    # inside the group
    return "│ #{text}" if @in_group

    # not in group
    "  " + text
  end

  def telegram_initialize
    token_file = File.expand_path("~/.bbh/telegram")

    unless File.exist?(token_file)
      msg = "telegram token is not specified, there will be no telegram logging"
      @logger.warn(group_prefix(msg))
      return { token: nil, chat_id: nil }
    end

    token = File.read(token_file).chomp
    uri = URI("https://api.telegram.org/bot#{token}/getUpdates")
    response = Net::HTTP.get(uri)
    updates = JSON.parse(response)

    if updates["result"] == []
      msg = "telegram bot has gone asleep, please send something to it and rerun the benchmark"
      @logger.error(group_prefix(msg))
      exit 0
    elsif updates["result"] == nil
      msg = "telegram bot not found, please check correctness of the token in #{token_file}"
      @logger.error(group_prefix(msg))
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

  def telegram_message(level, text, file: nil)
    return unless @telegram_token && @telegram_chat_id

    if file
      telegram_send_file(text, file)
      return
    end

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
    msg = "failed to send telegram chat message: #{e.message}"
    @logger.error(group_prefix(msg))
  end

def telegram_send_file(text, file)
  return unless File.exist?(file)
  uri = URI("https://api.telegram.org/bot#{@telegram_token}/sendDocument")
  f = File.open(file)

  form_data = {
    'chat_id' => @telegram_chat_id,
    'document' => UploadIO.new(f, 'application/octet-stream', File.basename(file))
  }
  form_data['caption'] = text if text

  request = Net::HTTP::Post::Multipart.new(uri.path, form_data)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.request(request)
ensure
  f.close if f
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

