from fastapi import FastAPI, Request
from ultralytics import YOLO
from io import BytesIO
from PIL import Image
import torch
import os

app = FastAPI()

device = os.getenv("DEVICE", "cuda" if torch.cuda.is_available() else "cpu")

if device == "cuda" and not torch.cuda.is_available():
    raise RuntimeError("ERROR: GPU is required but not available. Set MODEL_DEVICE=cpu to run on CPU.")

model = YOLO("yolov8n.pt").to(device)

dummy_image = Image.new("RGB", (640, 640))
_ = model(dummy_image)

@app.post("/predict/")
async def predict(request: Request):
    image_data = await request.body()

    image = Image.open(BytesIO(image_data))

    results = model(image)

    num_detected_objects = len(results[0].boxes)

    return num_detected_objects

