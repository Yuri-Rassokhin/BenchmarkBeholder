### PROJECT: what project this benchmark is a part of
$project_description = "OCI Object Storage"
$project_code = "kudu"
$project_tier = "test"

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "object_storage_coco_reading"
$series_description = 'Reading numerous images from OCI Object Storage on #{mode} #{shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@gmail.com"

# STARTUP: how to create the workload?
$startup_actor = "self" # No external actor needed, we'll run from within the hook
$startup_target = "bucket://coco-2017-images" # name of the bucket
$startup_type = "bucket" # type of the target
$startup_namespace = "fr9qm01oq44x" # workload-specific parameter

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_schedulers = "none" # Linux IO schedulers don't make any difference
$iterate_iterations = 4
$iterate_operations = "read" # workload-specific parameter: list of operations

# INFRASTRUCTURE
$infra_hosts = "127.0.0.1" # Benchmark Hosts
# User for passwordless ssh to the benchmark nodes
$infra_user = "opc" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")
