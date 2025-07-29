$series_benchmark = "xgboost_inference"
$series_description = 'requests per second for XGBoost prediction on #{mode} #{shape}'
$series_tier = "test"

$startup_actor = "self"
$startup_target = "http://127.0.0.1:8080/predict" # protocols: file, device, http, object, bucket, ram
$startup_target_application = "/tmp/target_fastapi.py"
$startup_model_path = "/tmp/xgboost_credit_fraud.pkl"
$startup_scaler_path = "/tmp/scaler.pkl"
$startup_device = "cpu"

$iterate_iterations = 4
$iterate_processes = "70, 80, 90, 100, 110, 120"
$iterate_requests = "70, 80, 90, 100, 110, 120"



# How to install XGBoost for inference in RPM-based Linux: ./source/hooks/xgboost_inference/configure.sh

