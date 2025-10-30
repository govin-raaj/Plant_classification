import os
import shutil
import random


dataset_dir = "D:/ML/Plant_classification_proj/data/25_plant_species" 
output_dir = "D:/ML/Plant_classification_proj/data/25_plant_species_split"  

# Split ratio
val_ratio = 0.2  # 20% for validation

train_dir = os.path.join(output_dir, "train")
val_dir = os.path.join(output_dir, "val")
os.makedirs(train_dir, exist_ok=True)
os.makedirs(val_dir, exist_ok=True)


classes = [d for d in os.listdir(dataset_dir) if os.path.isdir(os.path.join(dataset_dir, d))]
for cls in classes:
    cls_path = os.path.join(dataset_dir, cls)
    images = [f for f in os.listdir(cls_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    random.shuffle(images)
    
    val_count = int(len(images) * val_ratio)
    
    train_images = images[val_count:]
    val_images = images[:val_count]
    

    os.makedirs(os.path.join(train_dir, cls), exist_ok=True)
    os.makedirs(os.path.join(val_dir, cls), exist_ok=True)

    for img in train_images:
        shutil.copy(os.path.join(cls_path, img), os.path.join(train_dir, cls, img))
    for img in val_images:
        shutil.copy(os.path.join(cls_path, img), os.path.join(val_dir, cls, img))

print("Dataset split completed!")
print(f"Train folder: {train_dir}")
print(f"Validation folder: {val_dir}")
