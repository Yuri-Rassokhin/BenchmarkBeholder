$project_code = "kudu"
$project_tier = "test"

$series_benchmark = "yolo_training"
$series_description = 'time to complete the training of YOLO on #{mode} #{shape}'

$startup_actor = "self"
$startup_target = "file:///home/opc/.local/bin/yolo" # must be full path to "yolo" (v8) or "train.py" (v5), example: file:///home/john/yolov5/train.py or file:///home/john/.local/bin/yolo
$startup_model = "yolov8n"
$startup_dataset = "coco128.yaml"
$startup_epochs = "10"
$startup_image_size = "640"
$startup_batch = "16"
$startup_device = "cpu"

$iterate_iterations = 1
$iterate_schedulers = "none"

### How to install YOLO on yum-based Linux:
# sudo yum install -y pip mesa-libGL
# pip install yolo
# which yolo

