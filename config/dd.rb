### PROJECT: what project this benchmark is a part of
$project_description = "BBH demo"
$project_code = "kudu"
$project_tier = "test"

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "dd"
$series_description = '#{series_benchmark} on #{media} on #{mode} #{shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@gmail.com"

# STARTUP: app input to be able to start it up
$startup_executable = "/usr/bin/dd" # Path to the benchmarked executable
# NOTE: benchmark-specific parameter
$startup_media = "/file.dump" # Media the benchmark executable will be using (a file, a block device ...)

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_schedulers = "none, kyber, mq-deadline, bfq" # Linux IO schedulers: mq-deadline, bfq, kyber, none
# NOTE: benchmark-specific parameter
$iterate_sizes = "4096, 65536, 262144"
$iterate_operations = "read, write"
$iterate_iterations = 4

# INFRASTRUCTURE: where to run the benchmark
# Hosts to run the benchmark on
$infra_hosts = "dev"
# User for passwordless ssh to the benchmark nodes
$infra_user = "yuri"

