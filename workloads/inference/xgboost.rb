$series_benchmark = "xgboost_inference"
$series_description = 'requests per second for XGBoost prediction on #{mode} #{shape}'
$series_tier = "test"

$startup_actor = "self"
$startup_target = "http://127.0.0.1:8080/predict" # protocols: file, device, http, object, bucket, ram
$startup_target_application = "/tmp/target_fastapi.py"
$startup_model_path = "/tmp/xgboost_credit_fraud.pkl"
$startup_scaler_path = "/tmp/scaler.pkl"
$startup_device = "cuda"

$iterate_iterations = 4
$iterate_processes = "10, 20, 30, 40, 50, 60"
$iterate_requests = "10, 20, 30, 40, 50, 60"



# How to install XGBoost for inference in RPM-based Linux:
#
# sudo yum install -y pip 
# pip install gunicorn fastapi uvicorn xgboost python-multipart kaggle scikit-learn imblearn
#
# cp ./sources/hooks/xgboost_inference/prepare_and_train.py /tmp
# cp ./sources/hooks/xgboost_inference/target_fastapi.py /tmp
# cd /tmp
# kaggle datasets download -d mlg-ulb/creditcardfraud
# unzip creditcardfraud.zip
# python ./prepare_and_train.py
