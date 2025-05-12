#!/usr/bin/bash

sudo yum install -y pip 
pip install gunicorn fastapi uvicorn xgboost python-multipart kaggle scikit-learn imblearn
cp ./sources/hooks/xgboost_inference/prepare_and_train.py /tmp
cp ./sources/hooks/xgboost_inference/target_fastapi.py /tmp
cd /tmp
kaggle datasets download -d mlg-ulb/creditcardfraud
unzip -o creditcardfraud.zip
python ./prepare_and_train.py
