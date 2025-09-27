# app.py
import streamlit as st
import numpy as np
from PIL import Image
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.efficientnet import preprocess_input

# --- Class Names ---
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

# --- Load Full Model ---
@st.cache_resource
def load_full_model():
    model = load_model("../models/EfficientNet_full_model.keras")  # folder from model.save()
    return model

model = load_full_model()

# --- Streamlit App ---
st.title("Plant Species Classifier 🌱")
st.write("Upload a plant image and the model will predict its species.")

uploaded_file = st.file_uploader("Choose an image...", type=["jpg", "jpeg", "png"])

if uploaded_file is not None:
    img = Image.open(uploaded_file).convert("RGB")
    st.image(img, caption='Uploaded Image', use_column_width=True)
    
    # Preprocess image
    img = img.resize((224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = preprocess_input(img_array)
    
    # Make prediction
    predictions = model.predict(img_array)
    pred_class = class_names[np.argmax(predictions)]
    confidence = float(np.max(predictions))  # convert to float for Streamlit

    st.write(f"**Predicted Class:** {pred_class}")
    st.write(f"**Confidence:** {confidence:.2f}")
