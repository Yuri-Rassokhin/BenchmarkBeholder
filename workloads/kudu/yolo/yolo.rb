$project_code = "kudu"
$project_tier = "test"

$series_benchmark = "yolo_training"
$series_description = 'time to complete the training of YOLO on #{mode} #{shape}'

$startup_actor = "self"
$startup_target = "yolo" # must be full path to "yolo" (v8) or "train.py" (v5)
$startup_model = "yolov5n.pt"
$startup_dataset = "coco128.yaml"
$startup_epochs = "200"
$startup_image_size = "640"
$startup_batch = "16"
$startup_device = "0" # SPECIFY AS NEEDED

$iterate_iterations = 1
$iterate_schedulers = "none"

$infra_hosts = "127.0.0.1"
$infra_platform = "oci"
