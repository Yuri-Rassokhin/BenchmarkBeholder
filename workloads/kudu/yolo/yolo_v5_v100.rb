$project_code = "kudu"
$project_tier = "test"

$series_benchmark = "yolo_training"
$series_description = 'time to complete the training of YOLO on #{mode} #{shape}'

$startup_actor = "self"
$startup_target = "file:///home/ubuntu/.local/bin/yolo" # protocols: file, device, http, object, bucket, ram
$startup_model = "yolov5n.pt"
$startup_dataset = "coco128.yaml"
$startup_epochs = "200"
$startup_image_size = "640"
$startup_batch = "16"
$startup_device = "cuda:0" # cuda or cpu

$iterate_iterations = 1
$iterate_schedulers = "none"

$infra_hosts = "140.238.42.37"
$infra_user = "ubuntu"
$infra_platform = "oci" # allowed values: "oci" (TODO: "azure", "aws", "gcp", "nvidia", "misc")
