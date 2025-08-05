# BenchmarkBeholder

BenchmarkBeholder, or BBH, is a tool for performance benchmarking of ANY application against all combinations of input parameters of the application.
This approach is called sweep analysis, and it allows you to:

1. Determine optimal combination of input parameters of the application.
2. Determine suboptimal combinations of input parameters of the application.
3. Quantify influence of input parameters.
4. Disclose trends and/or correlations between input parameters and performance of the application.

BBH is highly useful for anwering such questions as:
- "How do I achieve the highest performance of my application?"
- "What application/ML model/filesystem/database/etc should I choose for the task?"

Given your application, BBH unfdolds the entire performance landscape for you. It makes benchmarking an efficient and comfortable as it implememts R.E.A.L. paradigm:

**R**eproducible: BBH stores benchmark results with their configuration, making them reproducible.

**E**xtensible: BBH integrates with ANY application in ANY environment, on ANY infrastructure.

**A**ccumulative: BBH stores benchmark results in one universal format, allowing you to easily compare and/or merge benchmark results over years - from different application versions, different HW generations, etc.

**L**ucid: BBH unfdolds the entire performance landscape for you, leaving no stone unturned: you can take your BA/BI tool and visualize all possible combinations of input parameters and their influence on the application.

# How Does It Work?

Any application can be integrated with BBH by writing a simple hook in Ruby. Out of box, BBH already has a collection of integrated applications.

BBH is invoked as the following:

* As input, BBH takes a config file describing *parameter space*, that is, a Cartesian of the valid values of all the parameters you want to benchmark your application against
* After that, BBH runs the application against all the  combinations from the parameter space
* During the runs, BBH collects specified application metrics, enriches them with infrastructure metrics, and pushes everything to a database
* Finally, the database of benchmark grows as a single, centralized table structured in accordance with your projects and/or user teams

# Quick Start

```
git clone https://github.com/Yuri-Rassokhin/BenchmarkBeholder
cd ./BenchmarkBeholder
```

For the sake of example, let's analyze influence of the parameters of `dd` utility on its performance.
Create a file to use as target of the benchmarking:

`dd if=/dev/zero of=/tmp/dump bs=1G count=10`

Of course, you can specify any path of the file, as you wish.
Open workload file `./workloads/dd.json` that describes how to benchmark `dd` against multitude of its input parameters, and specify `target` to point to your test file.

Now you can laucn the benchmarking:

```
./bbh ./workloads/dd.json
```

BBH will create a space of ALL combinations of parameters specified in `parameters` of `./workloads/dd.json` and benchmark `dd` on your test file against each combinations of the parameters:

This should give you an idea of how it works.
You can modify the workload file `./workloads/dd.json` for your needs or create your own.

By the way, BBH can run on remote nodes as well - you just speficy remote URLs of the nodes, and BBH will run the benchmarking on the nodes.
Remote launch only requires SSH access to the nodes.
It's up to you how to configure SSH access - you can set up passwordless access or set access credentials in `~/.ssh/config`.
Just type `./bbh -h` to see its command line options.

# Integrating BenchmarkBeholder to Your Application

BBH has been designed extensible, that is, easily integratable to any application.

To do that, you should create three files: workload file and two integration files (parameters file and benchmarking file).

## Workload File

This file describes your workload. For example, './workloads/dd.json':

```json
{
        "workload": {
                "hook": "dd", 		# integration subdirectory under ./sources/hooks/ where BBH will look for integration files
                "actor": "dd", 		# actor is a program you will use for benchmarking
                "target": "/tmp/dump", 	# What to benchmark
                "protocol": "file", 	# protocol clarifies type of the target: file, directory, mount, http, ram, gpu, etc.
                "iterations": 10,	# how many times to repeat each invocation of the benchmark (useful for stable results without transient side effects)
                "total_size": 1073741824,	# dd-specific: total size of the target file
                "units": "MB/s",		# units of the measured performance
                "precision": 10			# decimal precision of the measured performance
        },
        "parameters": {
                "scheduler": [ "none", "kyber", "bfq", "mq-deadline" ], # IO scheduler in Linux kernel
                "size": [ 4096, 8192, 16384, 32768, 65536, 131072, 524288, 1048576, 2097152, 4194304, 10485760, 104857600, 209715200 ], # r/w chunk size
                "operation": [ "read", "write" ] # operation
        }
}
```

## Parameters File

This file, `./sources/hooks/dd/parameters.rb`, describes syntax and allowed values of the parameters in your JSON workload file.
The file leverages DSL of a highly useful ruby library `dry-validation` and is pretty self-explainable.

```ruby
SCHEMA = Dry::Schema.JSON do

  required(:workload).hash do
    required(:hook).filled(:string)
    required(:protocol).filled(:string)
    required(:actor).filled(:string)
    required(:target).filled(:string)
    required(:iterations).filled(:integer, gt?: 0)
    required(:total_size).filled(:integer, gt?: 0)
    required(:units).filled(:string)
    required(:precision).filled(:integer, gt?: 0)
  end

  required(:parameters).hash do
    required(:scheduler).array(:string, min_size?: 1, included_in?: %w[none bfq mq-deadline kyber])
    required(:size).array(:integer, min_size?: 1, gt?: 0)
    required(:operation).array(:string, min_size?: 1, included_in?: %w[read write])
  end

end
```

## Benchmarking File

This file describes what functions (that is, metrics) to calculate for each combinations of parameters.
It follows DSL of 'flex-cartesian' Ruby library.

```ruby
class Benchmarking < Hook

def initialize(logger, config, target)
  super(logger, config, target)
end

private

# You must use .setup method to define all the functions you want to calculate for your workload
def setup
  result = ""

  # function 'command' provides full command to launches the benchmark
  # iterator 'v' is a vector that refers to current combination of input parameters
  self.func(:add, :command) do |v|
    case v.operation
      when "read"
        flow = "if=#{@config.target} of=/dev/null"
      when "write"
        flow = "if=/dev/zero of=#{@config.target}"
    end
    "#{@config.actor} #{flow} bs=#{v.size} count=#{(@config[:workload][:total_size]/v.size).to_i}".strip
  end

  # function 'result' launches the benchmark and captures its raw result
  self.func(:add, :result, hide: true) do |v|
    Scheduler.switch(@logger, v.scheduler, @target.infra[v.host][:volumes])
    result = Global.run(binding, v.host, proc { `#{v.command} 2>&1>/dev/null`.strip })
  end

  # function 'error' extracts possible error from raw result
  self.func(:add, :error) do |v|
    `echo "#{result}" | grep error`.strip
  end

  # function 'bandwidth' extracts benchmarked value of the bandwidth
  self.func(:add, :bandwidth) do |v|
    bw = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $1}'`.strip.to_f
    units = `echo "#{result}" | grep copied | sed -e 's/^.*,//' | awk '{print $2}'`.strip
    Utilities.convert_units(@logger, bw, from: units, to: v.units, precision: @config[:workload][:precision])
  end

  # function 'units' fetches units from config
  self.func(:add, :units) { @config[:workload][:units] }

  # these are built-in functions provided by BBH - they report infrastructure configuration of the current benchmark
  self.func(:add, :platform) { |v| @target.infra[v.host][:platform] }
  self.func(:add, :shape) { |v| @target.infra[v.host][:shape] }
  self.func(:add, :device) { |v| @target.infra[v.host][:device] }
  self.func(:add, :fs) { |v| @target.infra[v.host][:filesystem] }
  self.func(:add, :fs_block_size) { |v| @target.infra[v.host][:filesystem_block_size] }
  self.func(:add, :fs_mount_options) { |v| "\"#{@target.infra[v.host][:filesystem_mount_options]}\"" }
  self.func(:add, :type) { |v| @target.infra[v.host][:type] }
  self.func(:add, :volumes) { |v| @target.infra[v.host][:volumes] }
  self.func(:add, :kernel) { |v| @target.infra[v.host][:kernel] }
  self.func(:add, :os_release) { |v| @target.infra[v.host][:os_release] }
  self.func(:add, :arch) { |v| @target.infra[v.host][:arch] }
  self.func(:add, :cpu) { |v| @target.infra[v.host][:cpu] }
  self.func(:add, :cores) { |v| @target.infra[v.host][:cores] }
  self.func(:add, :cpu_ram) { |v| @target.infra[v.host][:cpu_ram] }
end

end
```










## Describe the workload

Perhaps you want to run benchmarking of your new workload. For the sake of example, let us suppose that you have AI vision application, for which you train an AI model, and you want to maximize the performance of the training, which means that you want to reduce training time as much as possible.

As your AI model trains on GPU devices, it reads massive amount of image files from some storage. Therefore, training time of your AI models depends on the bandwidth of the storage. To be exact, bandwidth of the storage should be good enough to keep GPU cores constantly busy, and there is no point for you to aim on even higher performance of the storage, because extra performance won't be able to accelerate trianing process if the GPU cores are fully saturated.

Here it comes! You have just found yourself in a classical situation that requires performance benchmarking. Moreover, it requires multidimensial analysis of the most influential factors of the perfomance - and this is exactly what BenchmarkBeholder has been created for :)

To reduce time of AI training and avoid unneeded extra cost, you have to clarify the following questions:

1. What is the minimal bandwidth that keeps my GPU cores constantly busy close to 100% utilization?

2. Of all storage options available on OCI, which one provides such optimal bandwidth at the minimal cost?

3. Are there any other factors influencing performance of the storage?

For the sake of brevity, let us assume that you have completed step 1 and found out the minimum required bandwidth is 5.0 gbps; and let us assume that you only have two storage options, local NVMe SSD in your compute instance, and object storage.

Local NVMe drives do provide 5.0 gbps, hence the question: **is it even possible to hit 5.0 gbps on object storage, and if yes, then what influential factors should we consider?**

Time has come to leverage BenchmarkBeholder to answer these questions.

## Define workload components

BenchmarkBeholder represents a workload as an **Actor** that initiates **Operation** on the **Target** and receives its result, all that happening in **Infrastructure**.
Let us define all four components in our example.

Perhaps the storage is an OCI Object Storage bucket named "coco-2017-images", located in the namespace "qwertyuiop", and the bucket contains all ~118,000 image files from the publicly available dataset COCO, version of 2017. Then the workload components will look like this.

* **Actor:** as there is no any particular application involved, we will be reading/writing directly from the integration hook.
* **Target:** A bucket named "coco-2017-images" located in the namespace "qwertyuiop".
* **Operation:** Just "read" once we only run AI training on the image files.
* **Infrastructure:** As we want to identify influential factors of the bandwidth, it makes sense to track CPU consumption and RAM consumption on the compute instance that run the actor; this way we will know if CPU or RAM can be a bottleneck.

## Define workload-specific parameters

Now that we defined workload components, let us decide what are the parameters specific to our workload?

Workload parameters

1. Startup Parameters
	* Location of the actor (not workload-specific, BBH supports it automatically)
	* Bucket name (not workload-specific, BBH supports target name automatically)
	* Namespace name
2. Parameters iteratable during benchmarking
        * Name of operation (in our example, we are only interested in "read" though)
3. Parameters collectable as result of every benchmark
	* CPU consumption (not workload-specific, BBH supports it automatically)
	* RAM consumption (not workload-specific, BBH supports it automatically)
	* Bandwidth demonstrated on the operation on the current image file

Note that many parameters that we need aren't specific for our workload - on the contrary, they are mandatory for ANY workload. Such parameters have already been implemented in BBH, and we don't actually have to consider their integration. Therefore, we have finalized the list of workload parameters:

Workload-specific parameters

1. Startup Parameters
        * Namespace name
2. Parameters iteratable during benchmarking
        * Name of operation (in our example, we are only interested in "read" though)
3. Parameters collectable as result of every benchmark
	* Bandwidth demonstrated on the operation on the current image file

## On workload parameters

As we saw in the previous paragraph, BBH distinguishes three groups of workload parameters.

* **Startup** are the input parameters that remain static during the benchmarking.

* **Iterate** are the input parameters that vary during benchmarking. A Cartesian of allowed values of all the iteratable parameters is called **parameter space** of the workload. BBH traverses the parameters space running the actor on each combination of values of the iteratable parameters.

* **Collect** are the output parameters that are calculated as BBH traverses the parameter space.

This comprehensive and flexible approach to workload parameters is the real power of BBH.

## Integrate the workload to BBH

Now, we will integrate our workload-specific parameters to BenchmarkBeholder by creating so-called integration hook.

1. Create directory for the hook: `mkdir ./hooks/oci_object_storage`. This directory will contain all the integration of the workload to BBH.

2. Define workload-specific input parameters (that is, "startup" and "iterate") by creating the file `./hooks/object_storage/config.rb`. Note that it's a template, where only class name and two parameters must be manually defined.

```
# class name must be the same as the directory name for the hook, starting from a capital
class Oci_object_storage < GenericConfig

  def initialize(conf_file) 
    @parameters = {
      # Adding customer parameter: namespace, which must be a non-empty string
      startup_namespace: VStr.new(non_empty: true),
      # Adding custom parameters: operation, which is a list of operation names, but in our case can only be "read"
      iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read"], iteratable: true)
    }
    load_conf(conf_file)
  end

end
```

Definition of the parameters above has a nuance, the directive `iteratable: true` for one of the two input parameters. This directive implements an extra flexibility for dealing with iteratable parameters. It simply denotes if the itereatlbe parameter should really be iterated through. This allows for dynamic enabling and disabling of particular dimensions during multi-dimensional analysis of performance.

3. Finally, let us implement output parameters ("collect" ones) by adding SQL definition of such parameters to another template file `./sources/hooks/oci_object_storage/schema.rb`:

```
SCHEMA = "
    add column collect_bandwidth int not null after iterate_operation
  "
```

4. Define semantics of how to run the workload, and how to fetch its results, by adding manual code to the final template file `./sources/hooks/oci_object_storage/launch.rb`:

TODO

That's it, the new workload has been integrated in BBH. Now we can run the benchmark of the new workload, as described in the next paragraph.


5. Add all the workload-specific input parameters (that is, "startup" and "iterate") to the workload configuration file `./config/oci_object_storage.rb` (file name must be identical to the hook name).

## Run the benchmarking of the newly integrated workload

Benchmarking configuration is defined in so-called **benchmark file**, where most of the parameters are available in BBH out of box, and some others are custom parameters integrated by the hook.

```
$startup_namespace = "qwertyuiop" # workload-specific parameter
$startup_operations = "read" # workload-specific parameter
```

