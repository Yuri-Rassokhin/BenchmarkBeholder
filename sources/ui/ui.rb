require 'logger'

class UILogger < Logger
  def initialize(*args)
    super(*args)
  end

  def add(severity, message = nil, progname = nil, &block)
    # Construct the log message using the logger's formatter
    formatted_message = formatter.call(format_severity(severity), Time.now, progname, message || block&.call)

    # Send the fully constructed message to your custom method
    output(formatted_message)

    # Write the message to the logger's destination
    super(severity, message, progname, &block)
  end

private

  def output(formatted_message)
    raise "This method must be instantiated in a UI subclass"
  end

end

# Example usage
#logger = CustomLogger.new($stdout)
#logger.formatter = proc do |severity, datetime, progname, msg|
#  "#{datetime}: [#{severity}] #{progname}: #{msg}\n"
#end

#logger.info("This is an info message")
#logger.error("This is an error message")

class UI < UILogger

  def initialize(*args)
    super(*args)
    # 'bbh.log', 1, 1_024_000
  end

  # output message to UI
  def output(message)
  # This method is called from the logger automatically
  end

  # capture message from UI
  def input(message)
  end

end
