# ----------------------
# Stage 1: Build stage
# ----------------------
FROM python:3.10-slim AS build

# Install system dependencies for PyTorch + OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libgl1 \
        libglib2.0-0 \
        wget \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only Python requirements first for caching
COPY backend/requirements.txt .

# Install Python dependencies (CPU-only PyTorch)
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy app code and model
COPY backend/ /app/
COPY final_model/runs/classify/train6/weights/best.pt /app/final_model/runs/classify/train6/weights/best.pt

# ----------------------
# Stage 2: Production stage
# ----------------------
FROM python:3.10-slim

# Install minimal system libraries needed for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1 \
        libglib2.0-0 \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed Python packages from build stage
COPY --from=build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=build /usr/local/bin /usr/local/bin

# Copy app code and model
COPY --from=build /app /app

# Expose API port
EXPOSE 8000

# Run API
CMD ["gunicorn", "fast_api:app", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
