# BenchmarkBeholder

BBH is a tool for large-scale performance benchmarking of any application.

# What it is

BBH brings value to R&D in performance analysis in the long run, in the large projects, when you need to

* Benchmark your workloads in hundreds or thousands iterations
* Run benchmarks on many machines
* Collect results in a centralized way through months and years
* Involve multiple users or multiple project teams
* Make the results easily reproducible
* Store the results in a form convenient for BI, such as PowerBI or Excel

In other words, it comes in handy to those who created a quick script for benchmarking a while ago, and now is drawning in chaos as the project grows. BBH will be accurately accumulating your benchmark results at the organization level, and keep it for years in a centralized database, always ready for analysis.

# What it is NOT

* BBH is an overkill for just one-time launch of your benchmark
* BBH is not a benchmarking tool per se. Rather, it's a benchmarking framework that takes a given benchmarking tool (or application), runs it in given configurations, and collects associated metrics

# How does it work?

Any application can be integrated with BBH by writing a simple hook in Ruby. Out of box, BBH already has a collection of integrated applications.

BBH is invoked as the following:

* As input, BBH takes a config file describing *parameter space*, that is, a Cartesian of the valid values of all the parameters you want to benchmark your application against
* After that, BBH runs the application against all the  combinations from the parameter space
* During the runs, BBH collects specified application metrics, enriches them with infrastructure metrics, and pushes everything to a database
* Finally, the database of benchmark grows as a single, centralized table structured in accordance with your projects and/or user teams

# Quick start

1. git clone https://github.com/Yuri-Rassokhin/BenchmarkBeholder
2. cd ./BenchmarkBeholder
3. ./bbh ./config/dummy.conf

This will give you an idea of how it works. After that, read through ./config/example.conf and start modifying it for your needs. BTW, you are welcome to check out other benchmark configurations under ./config ;)

# Installattion Guide

BBH operates in a distributed environment that consists of three logical roles.
**Central Host** is the host you're submitting benchmarks from. Usually, it's your local Linux machine or VM on the cloud you are going to use for benchmarking.
**Database Host** is the host that stores the database of benchmark results. By default, it's the central host.
**Benchmark Hosts** are the hosts you're running benchmarks on. As BBH is an agentless software, Benchmarks Hosts are actually ANY Linux hosts accessible via SSH.

1. Install BBH on Central Host: git clone https://github.com/Yuri-Rassokhin/BenchmarkBeholder

2. To maximize the performance of BBH, it is recommended to reuse once-established SSH connections. To achieve this, run this code:

mkdir -p ~/.ssh
touch ~/.ssh/config
echo "Host *
    ControlMaster auto
    ControlPath ~/.ssh/%r@%h:%p
    ControlPersist yes" >> ~/.ssh/config

3. Ensure the connectivity across your nodes accoring to the table.
