### PROJECT: what project this benchmark is a part of
$project_code = "test"
$project_tier = "test"

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "example"
$series_description = '#{$startup_actor} on #{$startup_target} on #{mode} #{shape}'
$series_owner_name = "John Doe"
$series_owner_email = "john.doe@acme.com"

# STARTUP: how to create the workload?
$startup_actor = "sleep" # No external actor needed, we'll run from within the hook
$startup_target = "file:///etc/hosts" # protocols: file, device, http, object, bucket, ram

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_iterations = 4 # MODIFY ME
$iterate_schedulers = "none, bfq, kyber, mq-deadline"

# INFRASTRUCTURE
$infra_hosts = "127.0.0.1" # ADDME: benchmark hosts
# User for passwordless ssh to the benchmark nodes
$infra_user = "opc" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")
