from backend.plant_api import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
import uvicorn
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import tensorflow as tf
import io
from PIL import Image

# Load trained model
model = load_model("../models/4.keras")  # <-- change if your file has a different name

image_size = 224

class_indices = {0: 'African Violet (Saintpaulia ionantha)', 1: 'Aloe Vera', 2: 'Anthurium (Anthurium andraeanum)', 3: 'Areca Palm (Dypsis lutescens)', 4: 'Asparagus Fern (Asparagus setaceus)', 5: 'Begonia (Begonia spp.)', 6: 'Bird of Paradise (Strelitzia reginae)', 7: 'Birds Nest Fern (Asplenium nidus)', 8: 'Boston Fern (Nephrolepis exaltata)', 9: 'Calathea', 10: 'Cast Iron Plant (Aspidistra elatior)', 11: 'Chinese Money Plant (Pilea peperomioides)', 12: 'Chinese evergreen (Aglaonema)', 13: 'Christmas Cactus (Schlumbergera bridgesii)', 14: 'Chrysanthemum', 15: 'Ctenanthe', 16: 'Daffodils (Narcissus spp.)', 17: 'Dracaena', 18: 'Dumb Cane (Dieffenbachia spp.)', 19: 'Elephant Ear (Alocasia spp.)', 20: 'English Ivy (Hedera helix)', 21: 'Hyacinth (Hyacinthus orientalis)', 22: 'Iron Cross begonia (Begonia masoniana)', 23: 'Jade plant (Crassula ovata)', 24: 'Kalanchoe', 25: 'Lilium (Hemerocallis)', 26: 'Lily of the valley (Convallaria majalis)', 27: 'Money Tree (Pachira aquatica)', 28: 'Monstera Deliciosa (Monstera deliciosa)', 29: 'Orchid', 30: 'Parlor Palm (Chamaedorea elegans)', 31: 'Peace lily', 32: 'Poinsettia (Euphorbia pulcherrima)', 33: 'Polka Dot Plant (Hypoestes phyllostachya)', 34: 'Ponytail Palm (Beaucarnea recurvata)', 35: 'Pothos (Ivy arum)', 36: 'Prayer Plant (Maranta leuconeura)', 37: 'Rattlesnake Plant (Calathea lancifolia)', 38: 'Rubber Plant (Ficus elastica)', 39: 'Sago Palm (Cycas revoluta)', 40: 'Schefflera', 41: 'Snake plant (Sanseviera)', 42: 'Tradescantia', 43: 'Tulip', 44: 'Venus Flytrap', 45: 'Yucca', 46: 'ZZ Plant (Zamioculcas zamiifolia)'}

# Initialize FastAPI
app = FastAPI(title="Plant Classifier API")

def preprocess_image(uploaded_file: UploadFile):
    """Preprocess uploaded image for model prediction"""
    contents = uploaded_file.file.read()
    img = Image.open(io.BytesIO(contents)).convert("RGB")
    img = img.resize((image_size, image_size))
    x = image.img_to_array(img)
    x = np.expand_dims(x, axis=0) / 255.0
    return x

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    try:
        # preprocess
        x = preprocess_image(file)

        # predict
        preds = model.predict(x)
        predicted_class = np.argmax(preds, axis=1)[0]
        confidence = float(np.max(preds))

        return JSONResponse(content={
            "predicted_class": class_indices[predicted_class],
            "confidence": round(confidence, 4)
        })

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
