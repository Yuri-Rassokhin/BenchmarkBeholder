from fastapi import FastAPI, Request
from ultralytics import YOLO

app = FastAPI()
model = YOLO("yolov8n.pt")
CLASS_NAMES = model.names

@app.post("/predict/")
async def predict(request: Request):
    # Read raw binary image data from request body
    image_data = await request.body()

    # Save to a temporary file
    with open("temp_image.jpg", "wb") as f:
        f.write(image_data)

    # Run YOLO inference
    results = model("temp_image.jpg")
    detected_objects = [CLASS_NAMES[int(box.cls)] for box in results[0].boxes]

    return {"objects": detected_objects}

