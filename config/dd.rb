### PROJECT: what project this benchmark is a part of
$project_description = "BBH demo"
$project_code = "kudu"
$project_tier = "test"

### SERIES: identification of this benchmark series
$series_benchmark = "dd" # name of one of the registered hooks
$series_description = '#{series_benchmark} on #{target} on #{mode} #{shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@gmail.com"

# STARTUP: app input to be able to start it up
$startup_actor = "/usr/bin/dd" # actor
$startup_target = "/file.dump" # target the actor will be using (a file, a block device ...)
$startup_type = "file"

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_iterations = 4 # how many times to repeat an invocation
$iterate_schedulers = "none, kyber, mq-deadline, bfq" # Linux IO schedulers: mq-deadline, bfq, kyber, none
$iterate_sizes = "4096, 65536, 262144" # workload-specific parameter
$iterate_operations = "read, write" # workload-specific parameter

# INFRASTRUCTURE: where to run?
$infra_hosts = "dev" # list of benchmark hosts
$infra_user = "yuri" # user for passwordless ssh to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")

