$project_code = "cheetah"
$project_tier = "test"

$series_benchmark = "yolo_inference"
$series_description = 'requests per second for YOLO object classification on #{mode} #{shape}'

$startup_actor = "self"
$startup_target = "http://127.0.0.1:8080/predict" # protocols: file, device, http, object, bucket, ram
$startup_target_application = "/tmp/target_fastapi.py"

$iterate_iterations = 4
$iterate_processes = "1, 2, 4, 8, 16, 32, 64"
$iterate_requests = "1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100"
$iterate_devices = "cuda, cpu"
$iterate_images = "/tmp/300.jpg"

$infra_hosts = "127.0.0.1"
$infra_user = "opc"
$infra_platform = "oci" # allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")

# dependencies
# Benchmark Nodes: sudo apt install -y apache2-utils
