### PROJECT: what project this benchmark is a part of
$project_code = "kudu"
$project_tier = "test"

### SERIES: identification of this benchmark series
$series_benchmark = "dummy"
$series_description = '#{$series_benchmark}, a simple BBH demo, running on #{$target} on #{$mode} #{$shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@gmail.com"

# STARTUP: app input to be able to start it up
$startup_path = "/tmp" # Directory under which the application is installed
$startup_src = "#{$startup_path}/dummy.sh" # Path to the actor

# ITERATE: what parameters to benchmark
$iterate_schedulers = "none" # Linux IO schedulers: mq-deadline, bfq, kyber, none

# COLLECT: How to collect benchmark numbers
# How many times to repeat every individual invocation (to accumulate statistics)
$collect_iterations = 4

# INFRASTRUCTURE: where to run the benchmark
# Hosts to run the benchmark on
$infra_hosts = "dev"
# User for passwordless ssh to the benchmark nodes
$infra_user = "yuri"

