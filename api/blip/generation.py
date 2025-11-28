"""
Módulo de generación de captions con BLIP
Configuración exacta que funciona con Python 3.11.9 + Transformers 4.53.2
"""
from transformers import BlipProcessor, BlipForConditionalGeneration
from PIL import Image
import torch
import sys


class BlipGenerator:
    def __init__(self, model_path="blip-final-5", device="cpu"):
        """Inicializa el modelo BLIP con configuración probada"""
        print(f"🔄 Cargando modelo BLIP: {model_path}")
        print(f"📋 Python: {sys.version}")
        
        try:
            import transformers
            print(f"📦 Transformers: {transformers.__version__}")
        except ImportError:
            print("❌ Transformers no disponible")
        
        self.device = torch.device(device)
        
        # Cargar modelo - configuración exacta del test exitoso
        self.processor = BlipProcessor.from_pretrained(model_path)
        self.model = BlipForConditionalGeneration.from_pretrained(model_path).to(self.device)
        self.model.eval()
        
        print(f"✅ Modelo BLIP cargado exitosamente en {self.device}")
    
    def generate_caption(self, image):
        """
        Genera caption usando la configuración EXACTA del notebook exitoso
        
        Args:
            image: PIL Image object
            
        Returns:
            str: Caption generado
        """
        # Convertir a RGB si no lo está
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        print(f"🤖 Generando caption para imagen {image.size}...")
        
        # Generar caption - EXACTAMENTE como en el test exitoso
        with torch.no_grad():
            inputs = self.processor(images=image, return_tensors="pt").to(self.device)
            out = self.model.generate(
                **inputs,
                max_new_tokens=1000,  # Configuración probada que funciona
                num_beams=3           # Configuración probada que funciona
            )
            caption = self.processor.decode(out[0], skip_special_tokens=True)
        
        print(f"✅ Caption generado: {len(caption)} caracteres")
        return caption.strip()


def generate_caption_from_image(image_path_or_pil, model_path="blip-final-5", device="cpu"):
    """
    Función independiente para generar caption
    Puede recibir ruta de imagen o PIL Image object
    """
    # Cargar modelo
    generator = BlipGenerator(model_path, device)
    
    # Cargar imagen si es ruta
    if isinstance(image_path_or_pil, str):
        image = Image.open(image_path_or_pil).convert("RGB")
    else:
        image = image_path_or_pil
    
    # Generar caption
    caption = generator.generate_caption(image)
    
    return caption


# Instancia global del generador (se carga una vez al importar el módulo)
_global_generator = None

def get_global_generator():
    """Obtiene o crea la instancia global del generador"""
    global _global_generator
    if _global_generator is None:
        _global_generator = BlipGenerator()
    return _global_generator


def quick_generate(image):
    """
    Función rápida usando el generador global
    Ideal para APIs donde solo necesitas generar sin recargar el modelo
    """
    generator = get_global_generator()
    return generator.generate_caption(image)


if __name__ == "__main__":
    # Prueba del módulo
    import sys
    if len(sys.argv) > 1:
        image_path = sys.argv[1]
        caption = generate_caption_from_image(image_path)
        print(f"Caption: {caption}")
    else:
        print("Uso: python generation.py <ruta_imagen>")