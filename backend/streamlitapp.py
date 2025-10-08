# app.py
import streamlit as st
from PIL import Image
from ultralytics import YOLO
import numpy as np

# --- Load the trained YOLOv8 model ---
@st.cache_resource
def load_model():
    model_path = "D:/ML/Plant_classification_proj/training/runs/classify/train/weights/best.pt"
    model = YOLO(model_path)
    return model

model = load_model()

# --- Streamlit UI ---
st.title("🌱 Plant Species Classifier")
st.write("Upload an image of a plant and the model will predict its species.")

uploaded_file = st.file_uploader("Choose an image...", type=["jpg", "jpeg", "png"])

if uploaded_file is not None:
    img = Image.open(uploaded_file).convert("RGB")
    st.image(img, caption="Uploaded Image", use_column_width=True)
    
    # --- Run prediction ---
    results = model.predict(np.array(img))
    
    # Show image with prediction
    results[0].plot(show=True)  # This opens in default image viewer
    st.image(results[0].plot(), caption="Prediction", use_column_width=True)
    
    # Get top-1 class
    class_index = int(np.argmax(results[0].probs))
    class_name = results[0].names[class_index]
    confidence = float(np.max(results[0].probs))
    
    st.write(f"**Predicted Class:** {class_name}")
    st.write(f"**Confidence:** {confidence:.2f}")
