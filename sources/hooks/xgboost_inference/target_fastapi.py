import os
import torch
import xgboost as xgb
from fastapi import FastAPI
import joblib
import numpy as np
import pandas as pd
from pydantic import BaseModel

# Paths from environment variables
MODEL_PATH = os.getenv("MODEL_PATH", "xgboost_credit_fraud.pkl")
SCALER_PATH = os.getenv("SCALER_PATH", "scaler.pkl")

# Detect device
device = "cuda" if os.getenv("DEVICE", "cpu") == "cuda" and torch.cuda.is_available() else "cpu"

app = FastAPI()

class TransactionInput(BaseModel):
    V1: float
    V2: float
    V3: float
    V4: float
    V5: float
    V6: float
    V7: float
    V8: float
    V9: float
    V10: float
    V11: float
    V12: float
    V13: float
    V14: float
    V15: float
    V16: float
    V17: float
    V18: float
    V19: float
    V20: float
    V21: float
    V22: float
    V23: float
    V24: float
    V25: float
    V26: float
    V27: float
    V28: float
    Amount: float

@app.on_event("startup")
def load_model():
    global model, scaler
    
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")

    if not os.path.exists(SCALER_PATH):
        raise FileNotFoundError(f"Scaler file not found: {SCALER_PATH}")

    print("Loading model and scaler...")
    
    model = joblib.load(MODEL_PATH)
    if device == "cuda":
        model.set_params(tree_method="hist", device="cuda")
# deprecated:       model.set_params(tree_method="gpu_hist")  # Enable GPU inference

    scaler = joblib.load(SCALER_PATH)
    print("Model and scaler loaded successfully.")

@app.post("/predict")
def predict(transaction: TransactionInput):
    # Convert input to DataFrame
    input_data = pd.DataFrame([transaction.dict()])
    
    # Scale the Amount column
    input_data['Amount'] = scaler.transform(input_data[['Amount']])

    # Convert input to numpy
    input_array = input_data.values

    if device == "cuda":
        input_array = np.array(input_array, dtype=np.float32)  # Ensure correct format
        dmatrix = xgb.DMatrix(input_array)  # No `device` argument
        model.set_params(predictor="gpu_predictor")  # ✅ Enable GPU inference
    else:
        dmatrix = xgb.DMatrix(input_array)  # CPU
        model.set_params(predictor="gpu_predictor")  # ✅ CPU inference

    # Predict
    predicted_class = model.predict(input_data)[0]
    predicted_prob = model.predict_proba(input_data)[0, 1]
    
    return {
        "Predicted Class": int(predicted_class),
        "Fraud Probability": float(predicted_prob)
    }

