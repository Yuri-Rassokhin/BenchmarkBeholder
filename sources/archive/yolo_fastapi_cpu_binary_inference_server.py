from fastapi import FastAPI, Request
from ultralytics import YOLO
from io import BytesIO
from PIL import Image
import torch

# Initialize YOLO model
model = YOLO("yolov8n.pt").to("cpu")  # Load model on CPU
CLASS_NAMES = model.names
#torch.set_num_threads(4)  # Optimize CPU threading

# Prewarm the model
dummy_image = Image.new("RGB", (640, 640))
_ = model(dummy_image)

app = FastAPI()

@app.post("/predict/")
async def predict(request: Request):
    # Read and process image
    image_data = await request.body()
    image = Image.open(BytesIO(image_data))  # Load image directly

    # Run YOLO inference
    results = model(image)
    detected_objects = [CLASS_NAMES[int(box.cls)] for box in results[0].boxes]

    # Return predictions
    return {"objects": detected_objects}

