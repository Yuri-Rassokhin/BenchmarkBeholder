### PROJECT: what project this benchmark is a part of
$project_description = "GPU Inference"
$project_code = "cheetah"
$project_tier = "test"

### SERIES: identification of this benchmark series
# NOTE: this one must correspond to the directory name of the hook and its classes
$series_benchmark = "llama_rag"
$series_description = 'Requests per second for LLAMA QA with RAG on #{mode} #{shape}'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@oracle.com"

# STARTUP: how to create the workload?
$startup_actor = "ab" # No external actor needed, we'll run from within the hook
$startup_target = "http://localhost:3000/llama/qa" # protocols: file, device, http, object, bucket, ram
#$startup_target_application = "/home/opc/yolo_server.py"
#$startup_health = "http://127.0.0.1:5000/health" # how to check if the target is available

# ITERATE: what parameters to benchmark? These parameters form the parameter namespace as a Cartesian
$iterate_iterations = 1
#$iterate_processes = "30, 60, 120"
$iterate_requests = "1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50"

# INFRASTRUCTURE
$infra_hosts = "130.61.28.203" # Benchmark Hosts
# User for passwordless ssh to the benchmark nodes
$infra_user = "ubuntu" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")

# dependencies
# Benchmark Nodes: sudo apt install -y apache2-utils
# NOTE: packages below may be specific for Ubuntu
# Benchmark Nodes: sudo apt install -y ruby-rubygems ruby-dev libyaml-dev
# Benchmark Nodes: sudo gem install pathname oci

