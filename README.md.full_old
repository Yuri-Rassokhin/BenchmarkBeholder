<p align="center">
  <img src="doc/pictures/bbh-logo-black.png" alt="BenchmarkBeholder Logo" width="100%"/>
</p>

# About

BenchmarkBeholder, abbreviated BBH, is a tool for performance benchmarking of ANY workload against ALL combinations of input parameters of the workload.
Without exaggeration, the workload can be anything you can measure: application, AI model, HTTP server, filesystem, database, block device, GPU, RAM, and so forth.

BBH helps you answer hot and practical questions:

* **HOW DO I TUNE MY WORKLOAD FOR THE HIGHEST PERFORMANCE AND SCALABILITY ?**
* **WHAT IMPLEMENTATION OF MY WORKLOAD SHOULD I CHOOSE FOR THE TASK ?**
* **HOW DO I PROVE IF MY WORKLOAD HAS BEEN TUNED AT ITS BEST ?**

BBH's approach of sweeping over all valid combinations of input parameters and benchmarking target metrics for each combination is called sweep analysis.
When it clarifies these three questions for you, it does it constructively: you will disclose optimal  and suboptimal combinations of parameters, quantified influence of parameters, and trends and edge cases, if any.

For instance, you need to choose an optimal AI model and SW+HW configuration for a chatbot. With BBH, you will easily:
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

Let's take an example. Perhaps, we want to answer the question: **how do I achieve the best ping latency to global DNS service?**
This workload has already been described in `./workloads/ping_dns.json`, here it is commented (note that JSON doesn't support comments, I only put them for clarity).

```jsonc
{
	// What application, service, or device to benchmark?
	"workload": {
		"hook": "ping_dns", // location of integration hook: schema of input parameters and how to fetch target metrics
                "actor": "ping",    // application to benchmark
                "iterations": 4     // how many times to repeat each invocation
        },
	// What combinations of parameter values to pass to the application?
	"parameters": {
                "dns": [ "8.8.8.8", "1.1.1.1", "208.67.222.222" ],
                "size": [ 16, 32 ]
        }
}
```

As you can see, the workload file simply describes
* What application to run?
* What parameters to pass to the application?
* How many times to repeat invocation with each combination of parameters?
* How to integrate BBH to the application:
  * What are input parameters of the application?
  * How to fetch target metrics during benchmarking?

Just type `./bbh ./workloads/ping_dns.json` to make `ping` benchmark against all `workload/parameters` described in the workload file:

<p align="center">
  <img src="doc/pictures/ping_dns.png" alt="Example of BBH output" width="60%"/>
</p>

The same results, reformatted as CSV, are saved in `./log/bbh-ping_dns-1754564563-result.csv`, where `ping_dns` is the name of workload, and `1754564563` is a globally unique identifier of the benchmarking series you just launched:

<p align="center">
  <img src="doc/pictures/ping_dns_csv.png" alt="Example of CSV output of BBH" width="60%"/>
</p>

Now, you can open the CSV file in any BA/BI tool you like, visualize it, and analyze performance sweetspots of the `ping` to DNS providers:

<p align="center">
  <img src="doc/pictures/bbh_output_chart.png" alt="Example of chart based on CSV output of BBH" width="60%"/>
</p>

# Telegram Logging

Benchmarking can take long time. For your convenience, you can tell BBH to duplicate its logging to [Telegram](https://telegram.org/) on your mobile device.
Then you'll be able to track progress in real time. This is especially convenient for debugging purposes, when you want to quickly see if something goes weird. Enabling Telegram logging takes two steps:
1. Create Telegram bot: open Telegram, search for `@BotFather`, type `/newbot` and follow instructions
2. Put the bot token to `~/.bbh/telegram` file on the machine that launches `./bbh`

That's it. During next launch, BBH will notice the token and start duplicating its log to your bot:

<p align="center">
  <img src="doc/pictures/ping_dns_telegram_started.png" alt="Bot logging started" width="30%"/>
  <img src="doc/pictures/ping_dns_telegram_completed.png" alt="Bot logging completed" width="30%"/>
</p>

NOTE: By design, Telegram makes inactive bot go asleep by timeout. If `./bbh` tells you that the bot has gone asleep, just awake the bot by sending any text to it.

# Workload Description
As we explore ping latency, we start from the fact that `ping` requires two parameters: URL of DNS provider and packet size.
Therefore, our workload file `./workloads/ping_dns.json` should specify valid values of these parameters. For instance, it can be the following (except for my comments - JSON doesn't support them):
```jsonc
{
        "workload": { 			// mandatory section: general configuration of the benchmark
                "hook": "ping_dns", 	// location of integration files: ./sources/hooks/ping_dns/
                "actor": "ping", 	// application to benchmark
                "iterations": 4		// how many times to repeat each invocation; comes in handy to build sustainable result
        },
        "parameters": { 		// mandatory section: input parameters to use during benchmarking
                "dns": [ "8.8.8.8", "1.1.1.1", "208.67.222.222" ],
                "size": [ 16, 32 ]
        }
}
```

This example gives you an idea of how you can describe ANY workload configuration for BBH.

# What Workloads Can I Benchmark?

You can benchmark literally _anything_ as long as you quickly write integration hook.
This repository includes a collection of ready-to-go workloads, updated regularly.

You can see already integrated workloads by typing `./bbh -v`.

# How Do I Add New Workload to BBH?

To benchmark a new workload, it must be integrated to BBH - here is step-by-step [explanation](./doc/integration.md) by example.
