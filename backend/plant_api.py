from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
from PIL import Image
import numpy as np
import torch

# Create FastAPI app
app = FastAPI(title="🌿 Plant Species Classifier API")

# Check if GPU is available
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"✅ Using device: {device}")

# Load YOLOv8 classification model
model = YOLO("D:/ML/Plant_classification_proj/training/runs/classify/train/weights/best.pt")  # path to your trained model
model.to(device)

# List of 30 class names (update according to your dataset)
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
        # Read image
        img = Image.open(file.file).convert("RGB")

        # Run YOLOv8 inference
        results = model.predict(source=np.array(img), imgsz=224, device=device, verbose=False)

        # Extract probabilities and prediction
        probs = results[0].probs.data.cpu().numpy()
        class_index = int(np.argmax(probs))
        pred_class = class_names[class_index] if class_index < len(class_names) else "Unknown"
        confidence = float(np.max(probs))

        return JSONResponse(content={
            "predicted_class": pred_class,
            "confidence": round(confidence * 100, 2)
        })

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@app.get("/")
async def root():
    return {"message": "🌿 Plant Classification API is running!"}
