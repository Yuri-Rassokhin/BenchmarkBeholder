$project_code = "cheetah"
$project_tier = "test"

$series_benchmark = "yolo_inference_fastapi_uvicorn_gpu"
$series_description = 'requests per second for YOLO object classification on #{mode} #{shape}'

$startup_actor = "ab"
$startup_target = "http://127.0.0.1:5000/predict" # protocols: file, device, http, object, bucket, ram
$startup_target_application = "/home/opc/yolo_server.py"

$iterate_iterations = 4
$iterate_processes = "30, 60, 120"
$iterate_requests = "10, 20, 30, 60, 120, 240"

$infra_hosts = "127.0.0.1"
$infra_user = "opc"
$infra_platform = "oci" # allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")

# dependencies
# Benchmark Nodes: sudo apt install -y apache2-utils
