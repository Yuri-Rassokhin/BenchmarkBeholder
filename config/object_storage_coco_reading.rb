### PROJECT: what project this benchmark is a part of
$project_description = "OCI Object Storage"
$project_code = "kudu"
$project_tier = "test"

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "dd"
$series_description = '#{series_benchmark} on #{target} on #{mode} #{shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@gmail.com"

# STARTUP: how to create the workload?
$startup_actor = "TODO" # No external actor needed, we'll run from within the hook
$startup_target = "coco-2017-images" # name of the bucket
$startup_type = "object"
$startup_namespace = "fr9qm01oq44x"

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_schedulers = "none" # Linux IO schedulers don't make any difference
# NOTE: benchmark-specific parameters
$iterate_operations = "read"
$iterate_iterations = 4

# INFRASTRUCTURE: where to run the benchmark
# Hosts to run the benchmark on
$infra_hosts = "dev"
# User for passwordless ssh to the benchmark nodes
$infra_user = "yuri"
$infra_platform = "oci"

