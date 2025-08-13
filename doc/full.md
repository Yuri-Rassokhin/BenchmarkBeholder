## BBH Approach

BBH performs sweep analysis — benchmarking every combination of parameters and collecting metrics to reveal optimal and suboptimal setups, parameter impact, trends, and edge cases.

## Benchmarking Workflow

Provide files describing:
- The workload to benchmark.
- Input parameters and their values.
- Metric collection logic.
- Optionally, benchmark preparations.

BBH:
- Builds the parameter space, that is, a combination of all valid combinations of input parameters.
- Benchmarks the workload for all combinations.
- Collects metrics (+ optional infrastructure metrics).
- Outputs a CSV report.

## Example: DNS Latency

### Workload file: `./workloads/ping_dns.json`

```jsonc
{
  "workload": {
    "hook": "ping_dns",
    "actor": "ping",
    "iterations": 4
  },
  "parameters": {
    "dns": [ "8.8.8.8", "1.1.1.1", "208.67.222.222" ],
    "size": [ 16, 32 ]
  }
}
```

Parameters in the `workload` section are mandatory:
- `hook`: location of integration hook.
- `actor`: the application for the benchmarking: fio, dd, ping, your Python script, or anything else.
- `iterations`: number of benchmark repetitions for each combination of input parameters; can be useful to derive sustained result without transient side effects.

Input parameters in the `parameters` section are application-specifis and defined by the creator of the workload file.
As ping accepts two parameters - target URL and packet size - the workload file defines these two and suggests ranges of reasonable values for each parameter.

## Parameter Schema: `./sources/hooks/ping_dns/schema.rb`

Now we should define valid syntax and semantics of the input parameters in the file referred to by `workload/hook` field in the workload file, `./sources/hooks/ping_dns/schema.rb`.
Its method `validate` describes syntax and valid values of the workload file in a pretty self-commenting way.

```ruby
module Schema
  module_function

def validate
  Dry::Schema.JSON do

    required(:workload).hash do # `workload` section
      required(:hook).filled(:string) # `hook` must be a string
      required(:actor).filled(:string) # `actor` must be a string
      required(:iterations).filled(:integer, gt?: 0) # iterations must be natural
    end

    required(:parameters).hash do # `parameters` section
      required(:dns).array(:string, min_size?: 1, included_in?: %w[8.8.8.8 1.1.1.1 208.67.222.222]) # DNS servers must be from the predefined list
      required(:size).array(:integer, min_size?: 1, gteq?: 16) # packet size must be array of naturals >= 16 (otherwise ping is unable to produce statistics)
    end
  end
end

end
```

## Target Metrics: `./sources/hooks/ping_dns/metrics.rb`

Now we should define the metrics that will be collected during the benchmarking for each combination of input parameters, in the file `./sources/hooks/ping_dns/metrics.rb`.
Its method `setup` defines functions to collect the metrics:

```ruby
module Metrics
  module_function

# In the `setup` method, you specify all the target metrics BBH should calculate for each combination of parameters
# Vector `v` scans all combination of input parameters
# You can refer to individual parameters by their names: `v.time`, `v.size`, using parameter names defined in your workload file
# BBH calls `setup` just once, at startup, to define know WHAT ьуекшсы and HOW it will have to derive during benchmarking
# After that, BBH launches the benchmarking - that is, scans `v` over all valid combinations of parameters
def self.setup(space, logger, config, target)
  result = {} # here we'll store raw result of PING
  space.func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
  space.func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
  space.func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time
  space.func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f } # extract min ping time
  space.func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f } # extract loss rate
end

end
```

The mechanism of functions is very flexible and simple:
- A function appears in the benchmarking report as a column named after the function.
- Functions can refer to one another, as well as variables and methods in your code. This makes functions a VERY powerful and flexible mechanism.
- If you don't need a function in the report, you just add the function with the flag `hide: true` - for instance, you may want to hide intermediate calculations such as `:raw_ping`
- BBH already includes a number of functions for your convenience, such as:
  - Detection of cloud platform and compute shape in the cloud.
  - Type of storage (LVM, RAID, filesystem, etc).

You can take a look at the predefined functions in more complicated workloads such as `./sources/hooks/dd/metrics.rb`.
As a summary, you can think of functions as columnar formulas in Libre Office, MS Excel of similar software.

## Benchmark Result

Every function you add in the metrics file will appear in the output as a column named after this function - `command`, `time`, `min`, and `loss`:

```bash
dns            | size | host      | series     | iteration | command                        | time  | min   | loss
8.8.8.8        | 16   | 127.0.0.1 | 1755118752 | 1         | ping -c 5 -s 16 8.8.8.8        | 0.828 | 0.783 | 0.0 
8.8.8.8        | 32   | 127.0.0.1 | 1755118752 | 1         | ping -c 5 -s 32 8.8.8.8        | 0.828 | 0.814 | 0.0 
1.1.1.1        | 16   | 127.0.0.1 | 1755118752 | 1         | ping -c 5 -s 16 1.1.1.1        | 0.841 | 0.791 | 0.0 
1.1.1.1        | 32   | 127.0.0.1 | 1755118752 | 1         | ping -c 5 -s 32 1.1.1.1        | 0.834 | 0.787 | 0.0 
208.67.222.222 | 16   | 127.0.0.1 | 1755118752 | 1         | ping -c 5 -s 16 208.67.222.222 | 0.725 | 0.679 | 0.0 
208.67.222.222 | 32   | 127.0.0.1 | 1755118752 | 1         | ping -c 5 -s 32 208.67.222.222 | 0.719 | 0.681 | 0.0
```

Each line of the output corresponds to unique combination from _parameter space_ and defines unique invocation of the benchmark:
- `dns` and `size` are input parameters defined in the workload file.
- `host` is the host that launches the benchmark (added as `./bbh` CLI option, defaults to localhost).
- `series` is a globally unique identifier of the `./bbh` launch.
- `iteration` is a mandatory parameter from the workload file.

The rest of the line is the metrics we defined using the metrics file: `command`, `time`, `min`, and `loss`.

BBH generates result on the screen in plain text table and saves its CSV version to `./log/bbh-<hook>-<series>-result.csv` file for analysis.
