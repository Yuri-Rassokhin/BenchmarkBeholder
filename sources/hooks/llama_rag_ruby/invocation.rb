
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
end

def invocation(config, iterator)
    
  # execute the benchmark and capture its raw output

  # Configuration
  url = URI('http://localhost:8000/llama/qa')
  payload = {
    question: "#{config[:startup_question]}",
    max_tokens: iterator[:tokens],
    temperature: iterator[:temperature]
  }.to_json
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
  responses.each do |response|
    result << ( response[:status] == "200" ? "#{JSON.parse(response[:body])["answer"]}; " : "ERROR; " )
    error_count += 1 if response[:status] != "200"
  end

    collect = { processing_time: time_elapsed, failed_requests: error_count, request_time_ratio: time_elapsed/iterator[:requests], answer: result }
    iterate = { iteration: iterator[:iteration], requests: iterator[:requests], tokens: iterator[:tokens], temperature: iterator[:temperature] }
    startup = { command: "self", language: "ruby", question: config[:startup_question] }

    return { startup: startup, iterate: iterate, collect: collect }
  end

