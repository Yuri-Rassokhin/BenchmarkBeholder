require 'telegram/bot'

class TelegramBot

def initialize(log = $STDOUT)
    @token = '7873552814:AAFfU3IcKy3RFgz00yMCBJefc4stR_qea_Y'
end

def run
    Telegram::Bot::Client.run(@token) do |bot|
        bot.listen do |message|
          puts message
        end
    end
end

end

bot = TelegramBot.new
bot.run

