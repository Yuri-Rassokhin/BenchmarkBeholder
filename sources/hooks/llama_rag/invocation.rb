
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

def invocation(config, iterator)
  require 'oci'
  require 'pathname'

    # execute the benchmark and capture its raw output
    command = "ulimit -n 65535; ab -n #{requests} -c #{requests} -p /home/ubuntu/payload.txt -T \"application/x-www-form-urlencoded\" http://localhost:3000/llama/qa 2>&1"
    raw_result = `#{command}`

    # extract benchmark results
    inference_time = `echo "#{raw_result}" | grep "Requests per second" | awk '{print $4}'`
    request_error_count = `echo "#{raw_result}" | grep "Failed requests" | awk '{print $3}'`
    failed_requests = ( request_error_count == 0 ? "" : request_error_count )

    collect = { inference_time: inference_time, failed_requests: failed_requests, cuda_error: "", response_error: ""}
    iterate = { iteration: iterator[:iteration], requests: iterator[:requests] }
    startup = { command: command.gsub("'", "''"), language: "bash" }

    return { startup: startup, iterate: iterate, collect: collect }
  end

