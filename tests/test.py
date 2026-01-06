import os
import pandas as pd
from transformers import BlipProcessor, BlipForConditionalGeneration
from PIL import Image
import torch
from tqdm import tqdm
from pathlib import Path

# Configuración
test_folder = r"C:\Users\EleXc\Music\TESIS\TESTING\test_dataset\nuevo dataset\estudios_sociales\familia\compromiso"
output_csv = r"C:\Users\EleXc\Desktop\tesis_app\predicciones_test4-compromiso.csv"
model_path = r"C:\Users\EleXc\Downloads\bliputf-esp-last2-20251224T072956Z-3-001\bliputf-esp-last2"  # Cambia por la ruta de tu modelo entrenado

# 1. Cargar modelo entrenado
print("Cargando modelo...")
device = "cpu"  # Usando CPU
processor = BlipProcessor.from_pretrained(model_path)
model = BlipForConditionalGeneration.from_pretrained(model_path).to(device)

# 2. Buscar todas las imágenes en la carpeta
print(f"Buscando imágenes en: {test_folder}")
image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.gif', '.webp']
image_files = []

for ext in image_extensions:
    image_files.extend(Path(test_folder).rglob(f"*{ext}"))

print(f"Encontradas {len(image_files)} imágenes")

# 3. Generar predicciones para cada imagen
predictions = []

for image_path in tqdm(image_files, desc="Generando predicciones"):
    try:
        # Cargar imagen
        image = Image.open(image_path).convert("RGB")
        
        # Generar predicción
        inputs = processor(images=image, return_tensors="pt").to(device)
        
        with torch.no_grad():
            out = model.generate(
                **inputs,
                max_new_tokens=100,
                num_beams=3,
                early_stopping=True
            )
        
        # Decodificar predicción
        caption = processor.decode(out[0], skip_special_tokens=True)
        
        # Guardar resultado
        relative_path = str(image_path.relative_to(Path(test_folder)))
        predictions.append({
            'imagen': relative_path,
            'prediccion': caption
        })
        
    except Exception as e:
        print(f"Error procesando {image_path}: {e}")
        predictions.append({
            'imagen': str(image_path.relative_to(Path(test_folder))),
            'prediccion': f"ERROR: {str(e)}"
        })

# 4. Guardar resultados en CSV
df_predictions = pd.DataFrame(predictions)
df_predictions.to_csv(output_csv, index=False, encoding='utf-8')

print(f"\n✅ Proceso completado!")
print(f"📊 Total de imágenes procesadas: {len(predictions)}")
print(f"📄 Resultados guardados en: {output_csv}")
print(f"\nPrimeras 5 predicciones:")
print(df_predictions.head())