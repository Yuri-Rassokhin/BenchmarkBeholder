class TelegramBot

def initialize(log)
    @token = '7873552814:AAFfU3IcKy3RFgz00yMCBJefc4stR_qea_Y'
    @processor = processor
    @converter = converter
    @modes = ["Identify use cases", "Generate solution"]
    @current_mode = "identify use cases" # Set a default mode
end

def run
    Telegram::Bot::Client.run(@token) do |bot|
        bot.listen do |message|
            case message

            when Telegram::Bot::Types::Message
              puts message.text
              if message.text == '/start'
                bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}! How can I assist you today?")
              elsif message.text == '/help'
                bot.api.send_message(chat_id: message.chat.id, text: "I am a digital architect at the AI Centre of Excellence, Oracle EMEA. If you describe your business case, I will identify relevant AI use cases and propose an optimal solution on Oracle Cloud Infrastructure. Just type your description! Here are a few examples for you to start with.")
                bot.api.send_message(chat_id: message.chat.id, text: "I want a drone to be monitoring progress on a construction site, daily.")
                bot.api.send_message(chat_id: message.chat.id, text: "AI solution for a retail business that performs the following tasks: identify customer sentiments from feedback, detect anomalies in daily sales data, and classify objects in inventory images.")
                bot.api.send_message(chat_id: message.chat.id, text: "A real-time translation between English and Arabic in a corporate chat and in a corporate headset. The translation must be provided for both channels, text and voice.")
              elsif message.text == '/mode'
                keyboard = @modes.map { |mode| Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{mode == @current_mode ? '🔘' : '⚪'} #{mode}", callback_data: mode) }
                markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard.each_slice(1).to_a)
                bot.api.send_message(chat_id: message.chat.id, text: 'Select mode:', reply_markup: markup)
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Thank you, let me think through")
                start_time = Time.now
                proposal = @processor.design(message.text)
                #md_to_html(proposal)
                picture = Tempfile.new(['image', '.png'])
                @converter.md_to_png(proposal, picture)
                end_time = Time.now
                bot.api.send_photo(chat_id: message.chat.id, caption: "Here is the solution for you, designed in #{(end_time - start_time).round} seconds", photo: Faraday::UploadIO.new(picture.path, 'image/png'))
                picture.close
                picture.unlink
                #bot.api.send_document(chat_id: message.chat.id, document: Faraday::UploadIO.new(attach, 'application/pdf'))
                #bot.api.send_message(chat_id: message.chat.id, text: "You said: #{message.text}")
              end

            when Telegram::Bot::Types::CallbackQuery
              # Handle button presses
              @selected_mode = message.data
              # Update the current mode
              @current_mode = @selected_mode

              # Create updated keyboard with the selected mode
              keyboard = @modes.map do |mode|
                Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{mode == @current_mode ? '🔘' : '⚪'} #{mode}", callback_data: mode)
              end
              markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard.each_slice(1).to_a)
              # Update the message to reflect the new selection
              bot.api.edit_message_text(chat_id: message.message.chat.id, message_id: message.message.message_id, text: "Select the mode:", reply_markup: markup)
              # Respond to the callback
              bot.api.answer_callback_query(callback_query_id: message.id, text: "Switched to '#{@selected_mode}'")

            end
        end
  end
end

end
