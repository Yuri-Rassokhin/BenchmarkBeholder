
# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimensions(config)
  [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_requests].to_a
  ]
end

# CUSTOMIZE: give names to the dimensions, as a comma-separated list
def dimension_naming
  [ :iteration, :requests ]
end

# CUSTOMIZE: if you need one-time intitialization before traversal of the pararameter space started, it's here
def prepare(config = nil)
  require 'tempfile'
  result = Tempfile.new
  result.write "question=What is the main topic of the documents?&max_tokens=300&temperature=0.7"
  return result.path
end

def invocation(config, iterator)
    
    # execute the benchmark and capture its raw output
    command = "ulimit -n 65535; ab -n #{iterator[:requests]} -c #{iterator[:requests]} -p #{prepare} -T \"application/x-www-form-urlencoded\" http://localhost:3000/llama/qa 2>&1"
    raw_result = `#{command}`

    # extract benchmark results
    inference_time = `echo "#{raw_result}" | grep "Requests per second" | awk '{print $4}'`.strip
    request_error_count = `echo "#{raw_result}" | grep "Failed requests" | awk '{print $3}'`.strip
    failed_requests = ( request_error_count == 0 ? "" : request_error_count )

    collect = { inference_time: inference_time, failed_requests: failed_requests, cuda_error: "", response_error: ""}
    iterate = { iteration: iterator[:iteration], requests: iterator[:requests] }
    startup = { command: command.gsub("'", "''"), language: "bash" }

    return { startup: startup, iterate: iterate, collect: collect }
  end

