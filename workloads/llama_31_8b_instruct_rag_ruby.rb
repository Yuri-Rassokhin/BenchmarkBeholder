$project_code = "cheetah"
$project_tier = "test"

$series_benchmark = "llama_31_8b_instruct_rag_ruby"
$series_description = 'LLAMA 3.1 8B Instruct and VLLM via uvicorn RAG app on #{mode} #{shape} 4xGPU'

$startup_actor = "self" # No external actor needed, we'll run from within the hook
$startup_target = "http://127.0.0.1:3000/llama/qa" # protocols: file, device, http, object, bucket, ram
$startup_question = "Who is Sherlock Holmes?"
$startup_model = ""

$iterate_iterations = 2
$iterate_requests = "1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100"
$iterate_schedulers = "none"
$iterate_tokens = "50, 100, 150, 200"
$iterate_temperature = "0.0, 0.1"

# INFRASTRUCTURE
$infra_hosts = "130.61.28.203" # Benchmark Hosts
$infra_user = "ubuntu" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")

# dependencies
# Benchmark Nodes: sudo apt install -y apache2-utils
# NOTE: packages below may be specific for Ubuntu
# Benchmark Nodes: sudo apt install -y ruby-rubygems ruby-dev libyaml-dev
# Benchmark Nodes: sudo gem install pathname oci

