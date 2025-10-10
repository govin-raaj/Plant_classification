from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
from PIL import Image
import numpy as np
import torch
import json
import os

# Initialize FastAPI app
app = FastAPI(title="🌿 Plant Species Classifier API with Info")

# Load the trained YOLOv8 model
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"✅ Using device: {device}")

model_path = "D:/ML/Plant_classification_proj/training/runs/classify/train/weights/best.pt"
model = YOLO(model_path)
model.to(device)

# Load plant info JSON
plant_info_path = "D:/ML/Plant_classification_proj/backend/plant_info.json"  # <-- update path if needed

if os.path.exists(plant_info_path):
    with open(plant_info_path, "r", encoding="utf-8") as f:
        plant_info = json.load(f)
    print("✅ Loaded plant_info.json successfully.")
else:
    plant_info = {}
    print("⚠️ plant_info.json not found. Continuing without extra info.")

# List of classes
class_names = [
    'African Violet (Saintpaulia ionantha)', 'Aloe Vera', 'Begonia (Begonia spp.)',
    'Birds Nest Fern (Asplenium nidus)', 'Boston Fern (Nephrolepis exaltata)',
    'Calathea', 'Cast Iron Plant (Aspidistra elatior)',
    'Chinese Money Plant (Pilea peperomioides)', 'Christmas Cactus (Schlumbergera bridgesii)',
    'Chrysanthemum', 'Ctenanthe', 'Dracaena', 'Elephant Ear (Alocasia spp.)',
    'English Ivy (Hedera helix)', 'Hyacinth (Hyacinthus orientalis)',
    'Iron Cross begonia (Begonia masoniana)', 'Jade plant (Crassula ovata)',
    'Money Tree (Pachira aquatica)', 'Orchid', 'Parlor Palm (Chamaedorea elegans)',
    'Peace lily', 'Poinsettia (Euphorbia pulcherrima)', 'Polka Dot Plant (Hypoestes phyllostachya)',
    'Ponytail Palm (Beaucarnea recurvata)', 'Pothos (Ivy arum)', 'Prayer Plant (Maranta leuconeura)',
    'Rattlesnake Plant (Calathea lancifolia)', 'Rubber Plant (Ficus elastica)',
    'Sago Palm (Cycas revoluta)', 'Schefflera', 'Snake plant (Sanseviera)',
    'Tradescantia', 'Tulip', 'Venus Flytrap'
]

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        # Load and convert image
        img = Image.open(file.file).convert("RGB")

        # Run inference
        results = model.predict(source=np.array(img), imgsz=224, device=device, verbose=False)

        # Extract prediction
        probs = results[0].probs.data.cpu().numpy()
        class_index = int(np.argmax(probs))
        pred_class = class_names[class_index] if class_index < len(class_names) else "Unknown"
        confidence = float(np.max(probs))

        # Get additional plant info from JSON
        info = plant_info.get(pred_class, None)

        response = {
            "predicted_class": pred_class,
            "confidence": round(confidence * 100, 2),
            "info": info if info else {"message": "No detailed info available for this plant."}
        }

        return JSONResponse(content=response)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@app.get("/")
async def root():
    return {"message": "🌿 Plant Classification API is running with detailed info!"}
