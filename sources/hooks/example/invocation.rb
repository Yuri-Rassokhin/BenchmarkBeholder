
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

