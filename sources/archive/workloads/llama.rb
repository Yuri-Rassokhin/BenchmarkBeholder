$project_code = "cheetah"
$project_tier = "test"

$series_benchmark = "llama"
$series_description = 'LLAMA and VLLM QA on #{mode} #{shape}'

$startup_actor = "self" # No external actor needed, we'll run from within the hook
$startup_target = "http://127.0.0.1:8000/v1/completions" # protocols: file, device, http, object, bucket, ram
$startup_question = "What is the capital of France?"

$iterate_iterations = 2
$iterate_requests = "2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000"
#$iterate_requests = "1, 10, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370, 380, 390, 400"
$iterate_schedulers = "none"
$iterate_tokens = "50, 100"
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

