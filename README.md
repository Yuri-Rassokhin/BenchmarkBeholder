# BenchmarkBeholder

BBH is a tool for large-scale performance benchmarking of any application.

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

# Integrating Your Benchmark To BenchmarkBeholder

Perhaps you want to benchmark a new workload. For the sake of example, let it be bandwidth of OCI Object Storage. To properly integrate the workload to BBH, let us plan the workload.
Suppose we have a bucket named "coco-2017-images" in OCI Object Storage located in the namespace "qwertyuiop", and the bucket contains around 118,000 image files from the publicly available dataset COCO, version of 2017. Suppose we want to benchmark bandwidth of reading and writing of the entire dataset. Therefore, to launch BBH series, we have to specify operation (read or write), bucket name, and bucket namespace. Our target metric is bandwidth of reading/writing. Therefore, during the benchmarking, we will be collecting bandwidth of reading/writing of each image file. Additionally, we will be collecting CPU utilization and RAM utilization of the OCI compute instance reading from/writing to the bucket, to get additional insight of how comptute capacity can influence the target metric. When all the images have been read/written, we will be able to use BI tool (MS Excel, PowerBI, etc.) to calculate the bandwidth of reading/writing of the entire dataset the way we want. For instance, we may calculate the bandwidth as the average of the bandwidth of all the images in the dataset.

Now, we can configure this workload.

* **Actor:** no external executable needed, we will be reading directly from the integration hook.
* **Target:** a bucket in OCI Object Storage named "coco-2017-images" located in the namespace "qwertyuiop".
* **Operation:** either "read" or "write".
* **Infrastructure:** OCI Compute Shape of the compute instance that runs the actor. Let's take Flex5.

To integrate this workload to BBH, we will do the following.

0. Create directory for the hook: `mkdir ./hooks/oci_object_storage`. This directory will contain all the integration of the workload to BBH.

1. Define workload-specific startup parameters. To launch the workload, we must know namespace of the bucket. Therefore, we are creating the file `./hooks/object_storage/config.rb`:

class Ddconfig < GenericConfig

  def initialize(conf_file) 
    @parameters = {
      startup_namespace: VStr.new(non_empty: true), # Namespace must be non-empty string
      iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read", "write"], iteratable: true) # Operations are given as the list of "read" or "write"
    }
    load_conf(conf_file)
  end

end

2. `./config/object_storage.rb`
```
$startup_namespace = "qwertyuiop" # workload-specific parameter
$startup_operations = "read"
```

2. Specify type and allowed values of the startup parameters. To do this, we are adding the following to 

class Ddconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      startup_namespace: VStr.new(non_empty: true), # Namespace must be non-empty string
      iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read", "write"], iteratable: true) # Operations are given as the list of "read" or "write"
    }
    load_conf(conf_file)
  end

end

2. Define workload-specific "collect" parameters. During the benchmarking we will be collecting 


