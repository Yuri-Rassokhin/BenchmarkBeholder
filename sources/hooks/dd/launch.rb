
class Dd < Collector

# Launch the loop for all runs aka invocations of the benchmark
def launch(config)
  # Commonly used to catch all output streams of the benchmark
  require 'open3'

  # Define commonly used variables
  total_invocations = config[:iteratable_size]
  media = config[:startup_media]
  executable = config[:startup_executable]

  # Define parameter space, a Cartesian of those parameters we want to iterate over
  dimensions = [
    (1..config[:collect_iterations]).to_a,
    config[:iterate_schedulers],
    config[:iterate_sizes],
    config[:iterate_operations]
  ]

  # Main loop: iterate over parameter space
  dimensions.inject(&:product).each do |iteration, scheduler, size, operation|
    #switch_scheduler $scheduler
    case operation
    when "read"
      flow = "if=#{config[:startup_media]} of=/dev/null"
    when "write"
      flow = "if=/dev/null of=#{config[:startup_media]}"
    end
    command = "#{executable} #{flow} bs=#{size}"
    # Commonly used: run the prepared command and capture its output
    #stdout, stderr, status = Open3.capture3("#{command}")
    end
end

end

