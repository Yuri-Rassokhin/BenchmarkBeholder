# BenchmarkBeholder

This is a tool that integrates with any application and benchmarks performance for any combination of influential parameters both of the application and infrastructure.
It will be highly useful if you regularly benchmark your workloads to explore how to reach highest performance.
BenchmarkBeholder makes benchmarking an efficient and comfortable process as it follows R.E.A.L. approach:

**R**eproducible: Every benchmark result is stored with its configuration, as such can be reproduced.

**E**xtensible: BenchmarkBeholder integrates with any application in any infrastructure.

**A**ccumulative: All benchmark results are stored in a single database, so you can easily compare influence of your evolving HW and/or application version over years.

**L**ucid: You application is benchmarked against any combination of any parameters that might infuence its performance, giving you completely transparent performance landscape of your workload.

# What It Is

BBH brings value to R&D in performance analysis in the long run, in the large projects, when you need to

* Benchmark your workloads in hundreds or thousands iterations
* Run benchmarks on many machines
* Collect results in a centralized way through months and years
* Involve multiple users or multiple project teams
* Make the results easily reproducible
* Store the results in a form convenient for BI, such as PowerBI or Excel

In other words, it comes in handy to those who created a quick script for benchmarking a while ago, and now is drawning in chaos as the project grows. BBH will be accurately accumulating your benchmark results at the organization level, and keep it for years in a centralized database, always ready for analysis.

# What It Is NOT

* BBH is an overkill for just one-time launch of your benchmark
* BBH is not a benchmarking tool per se. Rather, it's a benchmarking framework that takes a given benchmarking tool (or application), runs it in given configurations, and collects associated metrics

# How Does It Work?

Any application can be integrated with BBH by writing a simple hook in Ruby. Out of box, BBH already has a collection of integrated applications.

BBH is invoked as the following:

* As input, BBH takes a config file describing *parameter space*, that is, a Cartesian of the valid values of all the parameters you want to benchmark your application against
* After that, BBH runs the application against all the  combinations from the parameter space
* During the runs, BBH collects specified application metrics, enriches them with infrastructure metrics, and pushes everything to a database
* Finally, the database of benchmark grows as a single, centralized table structured in accordance with your projects and/or user teams

# Quick Start (Single Node)

```
git clone https://github.com/Yuri-Rassokhin/BenchmarkBeholder
cd ./BenchmarkBeholder
./bbh ./config/dummy.conf
```

This will give you an idea of how it works. After that, read through `./config/dummy.conf` and other benchmark files, and modify them for your needs.

# Detailed Configuration (Multiple Nodes)

BBH operates in a distributed environment that consists of three logical roles.

* **Central Node** is the host where you cloned the repo and are planning to submit benchmarks from. Usually, it's your local Linux machine or VM on a cloud.

* **Database Node** is the host that stores the database of benchmark results. By default, it's the central host.

* **Benchmark Nodes** are the hosts you're running benchmarks on. As BBH is an agentless software, Benchmarks Nodes are actually ANY Linux hosts accessible via SSH.

By default, all the three nodes are the host where you cloned the repo. If you want to specify other benchmark nodes and/or database node, please read the following section.

## Network Settings

1. In your benchmark file, specify the hosts where you want to run benchmark. For example: `$infra_nodes = "node01 node02"`. Note that this parameter doesn't specify whether your benchmark will run separate instances of the workload on each of these nodes or one distributed workload on all the nodes. All this parameter does is pass the host URLs to BBH. BBH will check availability and sanity of the nodes, and be reading infrastructure metrics from the nodes during the benchmarking. If you want to specify an array of multi-node workloads or a single distributed workload, you can do this with a custom hook.

2. To make Central Node reach out to Benchmark Nodes, ensure that passwordless SSH access is enabled from the Central Node to Benchmark Nodes for the user that will be submitting benchmarks.

3. To make Benchmark Nodes store benchmark results in the database, ensure that HTTP port 3306 is accessible from Benchmark Nodes to Database Node.

# Integrating New Benchmark To BenchmarkBeholder

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

