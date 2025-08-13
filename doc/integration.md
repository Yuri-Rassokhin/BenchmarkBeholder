# Integrating New Workload to BBH

Let us explain by example of the workload described in `./workloads/ping_dns.json`.

To integrate a new workload, you should create three files:
* **Workload Description:** `./workloads/ping_dns.json` - this file explains general configuration of the workload (`workload` section) and its input parameters for the benchmarking (`parameters` section).
* **Workload Schema:** `./source/hooks/ping_dns/schema.rb` - this file describes valid syntax and semantics of the workload file.
* **Workload Metrics:** `./source/hooks/ping_dns/metrics.rb` - this file describes target metrics to derive from the workload during benchmarking.
* **(Optional) Workload Preparation:** - this optional file would be named `prepare.rb`, and it would prepare benchmark environment: creates files, launches AI models, etc. In case of `ping_dns`, there is nothing to prepare.

Our workload file includes mandatory field `hook`:

```json
	"workload": {
		"hook": "ping_dns"
	}
```

Its values tells BBH where the schema and metrics files are located - in the `./sources/hooks/ping_dns` directory.

## Workload Schema

This file follows DLS of [dry-validation](https://rubygems.org/gems/dry-validation) Ruby library that describes syntax and semantics of JSON in a pretty self-commented manner.
Here is the workload schema file `./sources/hooks/ping_dns/schema.rb`:

```ruby
SCHEMA = Dry::Schema.JSON do

  required(:workload).hash do
    required(:hook).filled(:string) # hook must be a string
    required(:actor).filled(:string) # actor must be a string
    required(:iterations).filled(:integer, gt?: 0) # iterations must be a natural number
  end

  required(:parameters).hash do
    required(:dns).array(:string, min_size?: 1, included_in?: %w[8.8.8.8 1.1.1.1 208.67.222.222]) # DNS providers must be a list of valid URLs
    required(:size).array(:integer, min_size?: 1, gteq?: 16) # Packet size must be a list of integers >= 16 (for lesser values, PING is unable to generate statistics)
  end

end
```

When you run `./bbh ./workload/ping_dns.json`, BBH validates the .json workload description against the schema the workload file refers to by its `workload/hook` field.

## Workload Metrics

We also should specify what metrics BBH should calculate when it benchmarks our workload `ping_dns`.
Here is the workload metrics file `./sources/hooks/ping_dns/metrics.rb`:

```ruby
module Metrics
  module_function

# In the `setup` method, you specify all the target metrics BBH should calculate for each combination of parameters
# `space` refers to the parameters space, that is, collection of all combinations of input parameters
# Vector `v` refers to current combination from `space`
# The benchmarking process is `v` scanning through entire `space`, launching benchmark for each `v`, and deriving metrics from the benchmark
# You can refer to values of individual parameters by their names: `v.time`, `v.size`, etc, using the same parameter names as you defined in your workload file
# BBH will call `setup` just once, at startup, to define target metrics - that is, to know WHAT and HOW it should derive from the workload
# After that, BBH will launch the benchmarking, that is, scan `v` over `space`
# NOTE: If you need preparation before EACH combination is benchmarked, define it as one more `func(:add, ...)` and call it from the function that invokes benchmark
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

Usually, all you need to do is edit `setup` method by adding functions for launching your benchmark and deriving metrics from it.
Syntax `func(:add, ...)` is DSL of [flex-cartesian](https://rubygems.org/gems/flex-cartesian) Ruby library, which provides a simple way for defining functions on a Cartesian product (that is, on all combinations of given parameters).
The functions will be called for each combination of input parameters, `v`. Let's go through the functions in `ping_dns` example.

The function `command` constructs a `ping` command with current parameters.
```ruby
  func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
```

The function `raw_ping` executes `ping` command constructed by `command` function and caches its raw output in the variable `result[v.command]`.
Caching allows us to avoid excessive invocations of the same benchmarking command every time `raw_ping` is called.
Not only caching maintains consistency of the benchmarking results, but speeds up overall process as well.
```ruby
  func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
```

The function `time` extracts average ping time from the raw output provided by `raw_ping` function.
```ruby
  func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time from result
```

This should give you general idea of adding metrics, and we're omitting a couple of other functions, `min` to extract minimal ping time, and `loss` to extract loss rate.
Effectively, this is it.
Just a few final notes on the mechanism of functions:
- A function appears in the benchmarking report as a column of the values it calculates, column named after the function
- Functions can refer to one another, as well as variables and methods in your code. This makes functions a VERY powerful and flexible mechanism
- If you don't need a function to appear in the benchmarking report (for instance, intermediate calculations such as `:raw_ping`), you just add the function with the flag `hide: true`
- BBH already includes a number of functions for your convenience, chiefly for detection of infrastructure configurations (storage type, cloud platform, etc.) and retrieval of infrastructure metrics (CPU utilization, GPU utilization, etc.). You can take a look at these functions in more complicated workloads, such as `dd`: `./sources/hooks/dd/metrics.rb`

As a summary, you can think of functions as columnar formulas in Libre Office, MS Excel of similar software.
