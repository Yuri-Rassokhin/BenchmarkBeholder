$project_code = "cheetah"
$project_tier = "production"

$series_benchmark = "llama_rag_ruby"
$series_description = 'LLAMA RAG via FastAPI app with Ruby-threaded concurrent requests on #{mode} #{shape}'

$startup_actor = "self" # No external actor needed, we'll run from within the hook
$startup_target = "http://127.0.0.1.:3000/llama/qa" # protocols: file, device, http, object, bucket, ram
#$startup_health = "http://127.0.0.1:5000/health" # how to check if the target is available
$startup_question = "Who is it about?"

$iterate_iterations = 2
$iterate_requests = "50, 100"
#$iterate_requests = "1, 10, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370, 380, 390, 400"
$iterate_schedulers = "none"
$iterate_tokens = "100, 150, 200"
$iterate_temperature = "0.1, 0.5, 1.0"

# INFRASTRUCTURE
$infra_hosts = "130.61.28.203" # Benchmark Hosts
$infra_user = "ubuntu" # user for passwordless SSH to the benchmark nodes
$infra_platform = "oci" # which infrastructure platform we're running on, allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")

# dependencies
# Benchmark Nodes: sudo apt install -y apache2-utils
# NOTE: packages below may be specific for Ubuntu
# Benchmark Nodes: sudo apt install -y ruby-rubygems ruby-dev libyaml-dev
# Benchmark Nodes: sudo gem install pathname oci

