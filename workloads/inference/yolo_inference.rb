$project_code = "cheetah"
$project_tier = "test"

$series_benchmark = "yolo_inference"
$series_description = 'requests per second for YOLO object classification on #{mode} #{shape}'

$startup_actor = "self"
$startup_target = "http://127.0.0.1:8080/predict" # protocols: file, device, http, object, bucket, ram
$startup_target_application = "/tmp/target_fastapi.py"
$startup_device = "cpu"

$iterate_iterations = 4
$iterate_processes = "1, 2, 4, 8, 10, 20, 30, 40, 50, 60, 70, 80"
$iterate_requests = "1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100"
$iterate_images = "/tmp/300.jpg"

# How to install YOLO for inference in RPM-based Linux:
# sudo yum install -y pip mesa-libGL
# pip install gunicorn fastapi uvicorn yolo ultralytics
# which yolo
# cp ./sources/hooks/yolo_inference/target_fastapi.py /tmp/
# cp ./sources/hooks/yolo_inference/300.jpg /tmp/
