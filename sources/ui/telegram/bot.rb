require 'telegram/bot'
require 'net/http'
require 'uri'
require 'json'

class TelegramBot

  attr_reader :chat_id
def initialize(name: , surname: , token: , log: $STDOUT)
    @token = token
    @name = name
    @surname = surname
    @chat_id = get_chat_id
end

def msg(text)
  uri = URI("https://api.telegram.org/bot#{@token}/sendMessage")
  params = {
    chat_id: @chat_id,
    text: text
  }
  response = Net::HTTP.post_form(uri, params)
  puts "Response: #{response.body}" if response.is_a?(Net::HTTPSuccess)
rescue StandardError => e
  puts "Error: #{e.message}"
end

def run
    Telegram::Bot::Client.run(@token) do |bot|
        bot.listen do |message|
          puts message
        end
    end
end

private

def get_chat_id
  uri = URI("https://api.telegram.org/bot#{@token}/getUpdates")
  response = Net::HTTP.get(uri)
  updates = JSON.parse(response)
  updates["result"].each do |update|
    name = "#{update['message']['chat']['first_name']}"
    surname = "#{update['message']['chat']['last_name']}"
    return update['message']['chat']['id'] if name == @name and surname == @surname
  end
end

end

bot = TelegramBot.new(name: "Yuri", surname: "Rassokhin", token: '8103208089:AAEWSv3YSaFvWy38E1ucvpt_ikzoTKKO43c')

puts bot.chat_id
bot.msg "Hi"
#bot.run

