"""
Script de prueba para verificar generación de captions
Usa ruta de imagen estática para debugging
"""
import sys
import os
from PIL import Image
import torch

# Mostrar versiones para debug
print("=== INFORMACIÓN DEL SISTEMA ===")
print(f"Python: {sys.version}")
print(f"PyTorch: {torch.__version__}")

try:
    import transformers
    print(f"Transformers: {transformers.__version__}")
except ImportError:
    print("Transformers: NO INSTALADO")

try:
    from PIL import Image
    print(f"Pillow: {Image.__version__}")
except ImportError:
    print("Pillow: NO INSTALADO")

print("=" * 40)

# Configuración
MODEL_PATH = "blip-final-5"
# Cambia esta ruta por una imagen que tengas disponible
IMAGE_PATH = "C:\\Users\\EleXc\\Music\\TESIS\\TESTS\\burro_1.jpg"  # Asegúrate de que esta imagen existe

def test_generation():
    """Prueba la generación como en el notebook exitoso"""
    
    print(f"🔄 Cargando modelo: {MODEL_PATH}")
    
    try:
        from transformers import BlipProcessor, BlipForConditionalGeneration
        
        # Cargar modelo
        processor = BlipProcessor.from_pretrained(MODEL_PATH)
        model = BlipForConditionalGeneration.from_pretrained(MODEL_PATH).to("cpu")
        model.eval()
        
        print(f"✅ Modelo cargado exitosamente")
        
        # Verificar si existe la imagen
        if not os.path.exists(IMAGE_PATH):
            print(f"❌ ERROR: No se encuentra la imagen: {IMAGE_PATH}")
            print("Por favor, cambia IMAGE_PATH en el script por una imagen que exista")
            return
        
        print(f"🖼️ Cargando imagen: {IMAGE_PATH}")
        
        # Cargar imagen
        image = Image.open(IMAGE_PATH).convert("RGB")
        print(f"✅ Imagen cargada: {image.size}, modo: {image.mode}")
        
        print("🤖 Generando caption...")
        
        # Generar caption - EXACTAMENTE como en el notebook
        with torch.no_grad():
            inputs = processor(images=image, return_tensors="pt").to("cpu")
            out = model.generate(
                **inputs,
                max_new_tokens=1000,  # Igual que en notebook
                num_beams=3           # Igual que en notebook
            )
            caption = processor.decode(out[0], skip_special_tokens=True)
        
        print("=" * 60)
        print("RESULTADO:")
        print(f"Caption: {caption}")
        print("=" * 60)
        
        return caption
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    # Permitir especificar imagen como argumento
    if len(sys.argv) > 1:
        IMAGE_PATH = sys.argv[1]
        print(f"📁 Usando imagen especificada: {IMAGE_PATH}")
    
    result = test_generation()
    
    if result:
        print(f"\n✅ Prueba exitosa!")
        print(f"📝 Caption generado: {len(result)} caracteres")
    else:
        print(f"\n❌ Prueba fallida!")