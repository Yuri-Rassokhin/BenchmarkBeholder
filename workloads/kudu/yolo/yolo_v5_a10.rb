$project_code = "kudu"
$project_tier = "test"

$series_benchmark = "yolo_training"
$series_description = 'time to complete the training of YOLO on #{mode} #{shape}'

$startup_actor = "self"
$startup_target = "file:///home/opc/.local/bin/yolo"
$startup_model = "yolov5n.pt"
$startup_dataset = "coco128.yaml"
$startup_epochs = "200"
$startup_image_size = "640"
$startup_batch = "16"
$startup_device = "cuda" # cuda or cpu

$iterate_iterations = 1
$iterate_schedulers = "none"

$infra_hosts = "127.0.0.1"
$infra_user = "opc"
$infra_platform = "oci" # allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")
