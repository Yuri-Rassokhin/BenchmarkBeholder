
# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimensions(config)
  [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_requests].to_a,
    config[:iterate_tokens].to_a,
    config[:iterate_temperature]
  ]
end

# CUSTOMIZE: give names to the dimensions, as a comma-separated list
def dimension_naming
  [ :iteration, :requests, :tokens, :temperature ]
end

# CUSTOMIZE: if you need one-time intitialization before traversal of the pararameter space started, it's here
def prepare(config = nil)
  require 'net/http'
  require 'json'
  require 'thread'
  require 'method_source'

  Process.setrlimit(:NOFILE, 65535)
end

def invocation(config, iterator)

  def sanitise(content, max_length = 8192)

    content = content.gsub(/[\x00-\x1F]/, '')

    # Sanitize special characters
    content = content.gsub('\\', '\\\\\\')  # Escape backslashes
                     .gsub("'", "\\\\'")    # Escape single quotes
                     .gsub('"', '\\"')      # Escape double quotes
    # Truncate to fit within the database column size
    content = content[0, max_length]
    content
  end

  # execute the benchmark and capture its raw output

  # Configuration
  url = URI("#{config[:startup_target_protocol]}://#{config[:startup_target]}")
  payload = {
    "question": config[:startup_question],
    "max_tokens": iterator[:tokens],
    "temperature": iterator[:temperature],
    "stop": ["\n"]
}.to_json
  puts payload
  headers = { 'Content-Type' => 'application/json' }

  # Thread-safe collection for responses
  responses = []
  mutex = Mutex.new

  # Number of parallel requests
  concurrent_requests = iterator[:requests]

  # Create threads for parallel requests
  threads = []
  time_start = Time.now
  concurrent_requests.times do |i|
    threads << Thread.new do
      begin
        # Send POST request
        http = Net::HTTP.new(url.host, url.port)
        http.read_timeout = 3000 # Increase this value if needed
        http.open_timeout = 120 # Increase if connection setup takes time
        request = Net::HTTP::Post.new(url, headers)
        request.body = payload
        response = http.request(request)

        # Store response in thread-safe collection
        mutex.synchronize do
          responses << { id: i + 1, status: response.code, body: response.body }
        end
      rescue StandardError => e
        # Capture errors
        mutex.synchronize do
          responses << { id: i + 1, error: e.message }
        end
      end
    end
  end

  # Wait for all threads to complete
  threads.each(&:join)
  time_elapsed = Time.now - time_start

  # Print responses
  error_count = 0
  result = ""
  ref = ""
  failure = ""
  responses.each do |response|
    if response[:error]
      error_count += 1
      failure << response[:error] << "; "
      result = ""
      ref = ""
    else
      parsed_body = JSON.parse(response[:body])
      ref = parsed_body["relevant_documents"].join(", ")
      answer = parsed_body["answer"].strip
      puts answer
      result << "#{answer} "
    end
  end
  collect = { processing_time: time_elapsed, failed_requests: error_count, failure: failure, request_time_ratio: time_elapsed/iterator[:requests], answer: sanitise(result)[0..4095], references: sanitise(ref) }
    iterate = { iteration: iterator[:iteration], requests: iterator[:requests], tokens: iterator[:tokens], temperature: iterator[:temperature] }
    startup = { command: "self", language: "ruby", question: config[:startup_question] }

    return { startup: startup, iterate: iterate, collect: collect }
  end

