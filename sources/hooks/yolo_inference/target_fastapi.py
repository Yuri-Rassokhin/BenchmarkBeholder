from fastapi import FastAPI, Request
from ultralytics import YOLO
from io import BytesIO
from PIL import Image
import torch
import os

# Initialize FastAPI app
app = FastAPI()

# Get device from environment variable (default: "cuda" if available, otherwise "cpu")
device = os.getenv("DEVICE", "cuda" if torch.cuda.is_available() else "cpu")

# Ensure CUDA is available if "cuda" is requested
if device == "cuda" and not torch.cuda.is_available():
    raise RuntimeError("ERROR: GPU is required but not available. Set MODEL_DEVICE=cpu to run on CPU.")

# Load YOLO model on the specified device
model = YOLO("yolov8n.pt").to(device)

# Pre-warm the model with a dummy image
dummy_image = Image.new("RGB", (640, 640))
_ = model(dummy_image)

@app.post("/predict/")
async def predict(request: Request):
    # Read binary image data from the request body
    image_data = await request.body()

    # Load the image directly into memory using PIL
    image = Image.open(BytesIO(image_data))

    # Run YOLO inference on the selected device
    results = model(image)

    # Count the number of detected objects
    num_detected_objects = len(results[0].boxes)

    # Return the count of detected objects
    return num_detected_objects

