### PROJECT: what project this benchmark is a part of
$project_description = "GPU Inference"
$project_code = "cheetah"
$project_tier = "test"

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "yolo_inference_fastapi_uvicorn_gpu"
$series_description = 'Requests per second for image classification on #{mode} #{shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@gmail.com"

# STARTUP: how to create the workload?
$startup_actor = "ab" # No external actor needed, we'll run from within the hook
$startup_target = "http://127.0.0.1:5000/predict" # protocols: file, device, http, object, bucket, ram
$startup_health = "http://127.0.0.1:5000/health" # how to check if the target is available

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_iterations = 4
$iterate_processes = "30 60"
$iterate_requests = "30 60"

# INFRASTRUCTURE
$infra_hosts = "127.0.0.1" # Benchmark Hosts
# User for passwordless ssh to the benchmark nodes
$infra_user = "opc" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")
