# BenchmarkBeholder

BenchmarkBeholder, abbreviated BBH, is a tool for performance benchmarking of ANY workload against ALL combinations of input parameters of the workload.
Great news is that "workload" can be literally anything you can measure: application, AI model, HTTP server, filesystem, database, block device, GPU, RAM, and so forth. BBH helps you answer two very practical and hot questions:

* HOW DO I TUNE MY WORKLOAD FOR THE HIGHEST PERFORMANCE AND SCALABILITY ?
* WHAT IMPLEMENTATION OF MY WORKLOAD SHOULD I CHOOSE FOR THE TASK ?

This approach is called sweep analysis, and it allows you to:

* Give convincing, number-justified answers for these two questions
* In particular, it allows you to determine optimal combination of input parameters and quantify influence of input parameters

For instance, BBH allows you to compare and choose:
* Better performing AI model for your use case
* Optimal storage by performance/cost ratio for the AI model
* Assess performance of CPU RAM and decide if you should use CPU RAM as a cache of RAG index for the AI model
* Compare performance/price of GPU models to run your AI model

# What Makes it Cool

Given your workload, BBH unfdolds its entire performance landscape. This makes benchmarking insightful, efficient, comfortable, and complete - thanks to R.E.A.L. paradigm implanted in BBH:

**REPRODUCIBLE.** BBH stores benchmark results with their configuration, making them reproducible.

**EXTENSIBLE.** BBH integrates with ANY application in ANY environment, on ANY infrastructure.

**ACCUMULATIVE.** BBH stores benchmark results in one universal format, allowing you to easily compare and/or merge benchmark results over years, from different app versions, different HW generations, etc.

**LUCID.** BBH unfdolds the entire performance landscape for you, leaving no stone unturned: you can take your BA/BI tool and visualize all possible combinations of input parameters and their influence on the application.

# How it works

* As input, BBH takes *workload file* that describes
  * The workload you want to benchmark (in its simplest form, it's just application name, such as 'dd', 'ping', etc.)
  * All desired values of all input parameters of your workload
* BBH builds *parameter space*, that is, all combinations of the values of the parameters
* BBH invokes your workload against all combinations from the parameter space
* For each invocation, BBH collects metrics you specifed
* Optionally, BBH enriches them with infrastructure metrics from the environment it runs on
* Finally, BBH provides CSV report with benchmark results: combination of parameter values, calculated metrics, and (optional) infeastructure metrics

# Quick Start

BBH is simpler than it may seem :) Let's take an example. Perhaps, we want to answer the question:

**How do I achieve the best PING latency to global DNS service?**

To give it a go, just type

```bash
./bbh ./workloads/ping_dns.json
```

It will run through several invocations of `ping` command using different combinations of `ping` parameters:

# How it Works

When we investigate ping latency, we start from the fact that ping depends on two parameters:
- URL of DNS provider
- Packet size

Therefore, our workload file should describe values of these parameters. You can see it `./workloads/ping_dns.json`.

```json
{
        "workload": { 			# mandatory section: general configuration of the benchmark
                "hook": "ping_dns", 	# location of integration files: ./sources/hooks/ping_dns/
                "actor": "ping", 	# application to benchmark
                "iterations": 4		# how many times to repeat each invocation - comes in handy to make results sustainable
        },
        "parameters": { 		# mandatory section: input parameters to use during benchmarking
                "dns": [ "8.8.8.8", "1.1.1.1", "208.67.222.222" ],
                "size": [ 16, 32 ]
        }
}
```

# How to Integrate New Applications

For the sake of example, let us break down how `ping_dns` workloads is integrated into BBH.
The workload file includes mandatory field:

```json
	"workload": {
		...
		"hook: "ping_dns"
		...
	}
```

The hook points to the directory under `./sources/hooks` where two files reside:
- `workload.rb` describes schema (syntax and semantics) of the workload file
- `benchmarking.rb` describes how to calculate benchmarking metrics for each combination of input parameters from the workload file

## Creating workload.rb

This file follows notation of `dry-validation` Ruby library to describes valid syntax and semantics of the workload file. Here it is for `ping_dns`.

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

## Creating benchmarking.rb

This file describes what target metrics the benchmarking process will be calculating.
For any workload, it is the same pattern class which you put under './sources/hooks/<workload-name>' directory.
All you should do is to add target metrics to `./setup` method.
This method is called just once to define target metrics. After that, BBH actually starts benchmarking.

Here is the implementation for `ping_dns`.

```ruby
class Benchmarking < Hook

def initialize(logger, config, target)
  super(logger, config, target)
end

private

# In .setup, we specify what BBH should do for each combination of parameters, vector `v`
# `v` sweeps over all combinations of values specified in `parameters` section of the workload file
# This method is called just once and sets WHAT and HOW to benchmark.
# (If you need to arrange any one-time preparations before the benchnarking, you can do it from .setup
# However, if you need preparations before EACH combination is benchmarked, you should define it as a function below)
def setup
  result = {} # here we'll store raw result of PING
  func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
  func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
  func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time from result
  func(:add, :min) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = ([^\/]+)/, 1]&.to_f } # extract min ping time from result
  func(:add, :loss) { |v| v.raw_ping[/(\d+(?:\.\d+)?)% packet loss/, 1]&.to_f } # extract loss rate from result
end

end
```

To build parameter space and sweep over it, BBH uses `flex-cartesian` gem.
This gem simplifies such operations (calculating functions on Cartesian products) by introducing DSL that you can see in `.setup` body.
Statement of the kind...

```ruby
  func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
```

...defines a function that will be called for each combination of input parameters you described in the workload file `./workloads/ping_dns.json`.
You can define as many functions as you need, and the functions may call each other easily.
This gives you a simple and powerful approach for constructing chain of calculations for your target metrics.
For instance, once you added the function `:command` as given above, you can add a function to execute the command constructed by `:command` like that.

```ruby
  func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
```

The `:raw_ping` functions will be called for each combonation of input parameters, and it will store raw output of the ping in `result[v.command]` variable.
Now, we can use this variable to define the function that will be extracting ping time for each combination of input parameters:

```ruby
  func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time from result
```

Effectively, this is it. And the final notes:
- The functions you add are automatically added as columns in the benchmarking report BBH generated upon completion
- If you don't need a function in the benchmarking report (intermediate calculations such as `:raw_ping`), you just add this function with the flag `hide: true`

As the summary, you can think of functions as columnar formulas in Libre Office, MS Excel of similar software.

```
git clone https://github.com/Yuri-Rassokhin/BenchmarkBeholder
cd ./BenchmarkBeholder
```
