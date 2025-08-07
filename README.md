# BenchmarkBeholder

BenchmarkBeholder, abbreviated BBH, is a tool for performance benchmarking of ANY workload against ALL combinations of input parameters of the workload.
Without exaggeration, the "workload" can be anything you can measure: application, AI model, HTTP server, filesystem, database, block device, GPU, RAM, and so forth.

BBH helps you answer hot and practical questions:

* **HOW DO I TUNE MY WORKLOAD FOR THE HIGHEST PERFORMANCE AND SCALABILITY ?**
* **WHAT IMPLEMENTATION OF MY WORKLOAD SHOULD I CHOOSE FOR THE TASK ?**
* **HOW DO I PROVE IF MY WORKLOAD HAS BEEN TUNED AT ITS BEST ?**

BBH's approach of sweeping over all valid combinations of input parameters and benchmarking target metrics for each combination is called sweep analysis.
When it clarifies these three questions for you, it does it constructively: you will disclose optimal  and suboptimal combinations of parameters, quantified influence of parameters, and trends and edge cases, if any.

# What is It For?

Perhaps you need to choose an optimal AI model and SW+HW configuration for a chatbot. With BBH, you will easily:
* Compare and choose highest-performing AI model for your task
* Compare and choose optimal storage by performance/cost ratio
* Assess performance of CPU RAM and decide if you should use CPU RAM as RAG cache for your task
* Compare performance/price of different GPU models and choose the optimal GPU

# What Makes it Cool

Given your workload, BBH unfdolds its entire performance landscape. This makes benchmarking insightful, efficient, comfortable, and complete - thanks to R.E.A.L. paradigm implanted in BBH:

**REPRODUCIBLE.** BBH stores benchmark results together with configuration, input, and infrastructure metrics, making the result reproducible.

**EXTENSIBLE.** BBH integrates with ANY workload in ANY environment on different clouds: in particular, it detects [AWS](https://aws.amazon.com/), [Azure](https://azure.microsoft.com/), and [OCI](https://cloud.oracle.com/).

**ACCUMULATIVE.** BBH stores benchmark results in universal CSV format, allowing you to accumulate, compare, and merge them over years, for different app versions, HW generations, etc.

**LUCID.** BBH unfdolds the entire performance landscape for you, leaving no stone unturned: you can use any BA/BI tool to visualize and analyze performance landscape.

# Benchmarking Approach

* As input, BBH takes *workload file* that describes
  * The workload you want to benchmark
  * Desired values of input parameters of your workload
* BBH builds *parameter space*, that is, all combinations of the values of the parameters
* BBH invokes your workload against all combinations from the parameter space
* For each invocation, BBH collects metrics you specifed
* Optionally, BBH enriches them with infrastructure metrics from the environment it runs on
* Finally, BBH provides CSV report with benchmark results: combination of parameter values, calculated metrics, and (optional) infeastructure metrics

# Quick Start

Let's take an example. Perhaps, we want to answer the question: **"How do I achieve the best ping latency to global DNS service?"** Just type

```bash
./bbh ./workloads/ping_dns.json
```

BBH will run `ping` command with multiple different combinations of `ping` parameters, and generate a table with benchmark results upon completion:

<p align="center">
  <img src="doc/pictures/bbh_output.png" alt="Example of BBH output" width="40%"/>
</p>

The same results will be saved in CSV format to `./log/bbh-ping_dns-1754564563-result.csv`, where `ping_dns` is name of workload, and `1754564563` is unique identifier of the benchmarking series you initiated:

<p align="center">
  <img src="doc/pictures/bbh_output_csv.png" alt="Example of CSV output of BBH" width="40%"/>
</p>

Now, you can open the CSV file in any BA/BI tool you like to visualize it and analyze performance sweetspots of the `ping` to DNS providers:

<p align="center">
  <img src="doc/pictures/bbh_output_chart.png" alt="Example of chart based on CSV output of BBH" width="40%"/>
</p>

# Telegram Logging

Benchmarking can take long time. For your convenience, you can tell BBH to duplicate its logging to [Telegram](https://telegram.org/) on your mobile device.
Then you'll be able to track progress in real time, whatever you do.
This is especially convenient for debugging purposes, when you want to quickly see if something goes weird.

You can enable Telegram logging in two steps:
1. Create Telegram bot: open Telegram, search for @BotFather, type `/newbot` and follow instructions
2. Put the bot token to `~/.bbh/telegram` file on the machine that launches `./bbh`

That's it. During next launch, BBH will notice the token and start duplicating its log to your bot:

<p align="center">
  <img src="doc/pictures/bbh_bot_logging_started.jpg" alt="Bot logging started" width="40%"/>
  <img src="doc/pictures/bbh_bot_logging_completed.jpg" alt="Bot logging completed" width="40%"/>
</p>

NOTE: By design, Telegram makes inactive bot go asleep by timeout. If `./bbh` tells you that the bot has gone asleep, just awake the bot by sending any text to it.

# How it Works

As we explore ping latency, we start from the fact that `ping` requires two parameters: URL of DNS provider and packet size.
Therefore, our workload file `./workloads/ping_dns.json` should specify valid values of these parameters. For instance, it can be the following:

```json
{
        "workload": { 			# mandatory section: general configuration of the benchmark
                "hook": "ping_dns", 	# location of integration files: ./sources/hooks/ping_dns/
                "actor": "ping", 	# application to benchmark
                "iterations": 4		# how many times to repeat each invocation; comes in handy to build sustainable result
        },
        "parameters": { 		# mandatory section: input parameters to use during benchmarking
                "dns": [ "8.8.8.8", "1.1.1.1", "208.67.222.222" ],
                "size": [ 16, 32 ]
        }
}
```

# How to Integrate New Applications

You can describe any workload you want, and integrate it to BBH.
For the sake of example, let's have a look `ping_dns` integration.
Its workload file includes mandatory field:

```json
	"workload": {
		"hook: "ping_dns"
	}
```

The hook points to the directory under `./sources/hooks/ping_dns` where two integration files reside:
- Schema of the workload file: `workload.rb`
- Description of the metrics that must be calculated for each combination of parameters: `benchmarking.rb`

## Creating Workload Schema

This file follows notation of [dry-validation](https://rubygems.org/gems/dry-validation) Ruby library that describes syntax and semantics of JSON in a self-commenting manner.
In our example, here is the schema file `./sources/hooks/ping_dns/workload.rb`:

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

Whenever you run `./bbh my-workload-file` and my-workload-file refers to the hook `ping_dns`, the schema above will apply to it, and BBH will check syntax and semantics of your workload file.

## Creating Target Metrics

Now you need to specify what metrics BBH should calculate during benchmarking.
In our example, this file is `./sources/hooks/ping_dns/benchmarking.rb`:

```ruby
class Benchmarking < Hook

def initialize(logger, config, target)
  super(logger, config, target)
end

private

# In this method, you specify all the target metrics BBH should calculate for each combination of parameters
# Vector `v` in the method refers to current combinations of parameters
# You can refer to value of individual parameter by name: `v.time`, `v.size`, etc - using the same parameter names as you defined in your workload file
# BBH will call this method just once, at startup, to define target metrics: that is, WHAT and HOW it should benchmark
# After that, BBH will launch the benchmarking
# NOTE: If you need to pre-benchmark preparations, you can just place them in the beginning of this method
# NOTE: If you need preparation before EACH combination is benchmarked, just add it as one more func(:add, ...) and call it from the function that invokes benchmark
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

All you need to edit in this class is `setup` method.
Calls `func(:add, ...)` are the DSL of [flex-cartesian](https://rubygems.org/gems/flex-cartesian) Ruby library, which provides a simple way for defining functions on a Cartesian product (that is, on all combinations of given parameters). Let's go through the functions in our example. The following functions are added to be called for each combination of parameters, `v`.

This function constructs a `ping` command with current parameters, as a string.
```ruby
  func(:add, :command) { |v| "ping -c #{v.count} -s #{v.size} #{v.dns}" } # construct PING command with current combination of parameters
```

This function executes `ping` command constructed by the previous function and stores its raw output in `result[v.command]` variable.
```ruby
  func(:add, :raw_ping, hide: true) { |v| result[v.command] ||= `#{v.command} 2>&1` } # run PING and capture its raw result
```

This function extracts average ping time from the raw output stored in `result[v.command]`
```ruby
  func(:add, :time) { |v| v.raw_ping[/min\/avg\/max\/(?:mdev|stddev) = [^\/]+\/([^\/]+)/, 1]&.to_f } # extract ping time from result
```

A couple of similar functions follow, one to extract minimal ping time, and another to extract loss rate. Effectively, this is it. And the final notes on the mechanism of functions
- A function will appear in the benchmarking report as a column of the values it calluates, column name will be the function name
- Functions can refer to one another as well as to variables - such as `result` - and other methods in your code. This makes them a powerful mechanism
- If you don't need a function to appear in the benchmarking report (intermediate calculations such as `:raw_ping`), you just add the function with the flag `hide: true`

As the summary, you can think of functions as columnar formulas in Libre Office, MS Excel of similar software.

