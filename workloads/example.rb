### PROJECT: what project this benchmark is a part of
$project_description = "ADDME"
$project_code = "cheetah" # MODIFY ME
$project_tier = "test" # MODIFY ME

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "example"
$series_description = 'ADDME. You can use #{mode} and #{shape} variables here'
$series_owner_name = "ADDME"
$series_owner_email = "ADDME"

# STARTUP: how to create the workload?
$startup_actor = "self" # No external actor needed, we'll run from within the hook
$startup_target = "file:///dev/null" # protocols: file, device, http, object, bucket, ram

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_iterations = 4 # MODIFY ME

# INFRASTRUCTURE
$infra_hosts = "localhost" # ADDME: benchmark hosts
# User for passwordless ssh to the benchmark nodes
$infra_user = "opc" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")
