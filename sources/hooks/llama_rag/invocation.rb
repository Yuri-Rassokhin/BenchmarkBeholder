
# CUSTOMIZE: add dimensions for your iteratable parameters in the form config[:my_option].to_a, for instance: config[:iterate_requests].to_a, comma-separated
def dimensions(config)
  [
    (1..config[:iterate_iterations]).to_a
  ]
end

# CUSTOMIZE: give names to the dimensions, as a comma-separated list
def dimension_naming
  [ :iteration ]
end

def invocation(config, iterator)
  total_invocations = config[:parameter_space_size]
  target = config[:startup_target]
  actor = config[:startup_actor]

  # CUSTOMIZE: add the modules required for your hook
  require 'oci'
  require 'pathname'

  # CUSTOMIZE: add initialization of the variables relevant to your target
  language = "bash"

  # CUSTOMIZE: add your dimensions here in the form config[:my_option].to_a
  dimensions = [
    (1..config[:iterate_iterations]).to_a,
    config[:iterate_requests].to_a
  ]

  # CUSTOMIZE: add your iterator names
  cartesian(dimensions).each do |iteration, requests|
    # CUSTOMIZE: add your semantics of the benchmark invocation

    # execute the benchmark and capture its raw output
    command = "ulimit -n 65535; ab -n #{requests} -c #{requests} -p /home/ubuntu/payload.txt -T \"application/x-www-form-urlencoded\" http://localhost:3000/llama/qa 2>&1"
    raw_result = `#{command}`

    # extract benchmark results
    inference_time = `echo "#{raw_result}" | grep "Requests per second" | awk '{print $4}'`
    request_error_count = `echo "#{raw_result}" | grep "Failed requests" | awk '{print $3}'`
    failed_requests = ( request_error_count == 0 ? "" : request_error_count )

    # push benchmark results to the database
    collect = { inference_time: inference_time, failed_requests: failed_requests, cuda_error: "", response_error: ""}
    iterate = { iteration: iteration, requests: requests }
    startup = { command: command.gsub("'", "''"), language: language }
    push(config, collect, iterate, startup)
  end

end


# CUSTOMIZE: describe how to invoke a benchmark and captures all the data
def invocation(config, iterator)
  # note: don't forget to 'require' anything you will need on the node
  # this is the main part, add your semantics of the benchmark invocation
  command = "sleep 5 2>&1"
  raw_result = `#{command}`
  # capture eyour collectable parameters
  collect = { }
  # capture your iteratable parameters
  iterate = { iteration: iterator[:iteration] }
  # capture your startup parameters
  startup = { command: command.gsub("'", "''"), language: "bash" }
  return { startup: startup, iterate: iterate, collect: collect }
end

