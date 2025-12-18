import os
from optimum.exporters.onnx import main_export

MODEL_DIR = r"C:\Users\EleXc\Desktop\tesis_app\api\blip-final-5"
OUTPUT_DIR = r"C:\Users\EleXc\Desktop\tesis_app\api\blip-final-5-onnx"

os.makedirs(OUTPUT_DIR, exist_ok=True)

print("🚀 Iniciando exportación a ONNX...")

main_export(
    model_name_or_path=MODEL_DIR,
    output=OUTPUT_DIR,
    task="image-to-text",   # 👈 clave
)

print("✅ Exportación completada:", OUTPUT_DIR)
