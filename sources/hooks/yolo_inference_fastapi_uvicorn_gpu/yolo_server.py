from fastapi import FastAPI, Request
from ultralytics import YOLO
from io import BytesIO
from PIL import Image
import torch

# Initialize FastAPI app
app = FastAPI()

# Ensure GPU is available
if not torch.cuda.is_available():
    raise RuntimeError("ERROR: GPU is required to run this application.")

# Load YOLO model on GPU
model = YOLO("yolov8n.pt").to("cuda")

# Pre-warm the model with a dummy image
dummy_image = Image.new("RGB", (640, 640))
_ = model(dummy_image)

@app.post("/predict/")
async def predict(request: Request):
    # Read binary image data from the request body
    image_data = await request.body()

    # Load the image directly into memory using PIL
    image = Image.open(BytesIO(image_data))

    # Run YOLO inference on the GPU
    results = model(image)

    # Count the number of detected objects
    num_detected_objects = len(results[0].boxes)

    # Return the count of detected objects
    return {"num_objects": num_detected_objects}

