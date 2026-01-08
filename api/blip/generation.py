"""
============================================
🎯 BLIP Español - Modelo con Corrector Ortográfico Integrado
============================================

Este módulo contiene la clase BlipEspanol que envuelve el modelo BLIP
con un corrector ortográfico automático para español.

Características:
- Genera captions en español con corrección automática de tildes y eñes
- Optimizado para CPU con cuantización INT8
- Corrección ortográfica integrada y transparente
- Compatible con Raspberry Pi

Uso:
    modelo = BlipEspanol.from_pretrained("blip-final-5")
    caption = modelo.predict("imagen.jpg")  # ← Ya viene corregido
"""

from transformers import BlipProcessor, BlipForConditionalGeneration
from PIL import Image
import torch
import os
import re
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Importar diccionario personalizado
from .diccionario_es import obtener_correcciones, obtener_vocabulario

# Forzar uso de CPU si hay incompatibilidad CUDA
os.environ['CUDA_VISIBLE_DEVICES'] = ''


class BlipEspanol:
    """
    Modelo BLIP con corrector ortográfico integrado para español.
    
    Funciona igual que BlipForConditionalGeneration, pero automáticamente
    corrige la ortografía española (tildes, eñes, etc.).
    
    El corrector está DENTRO del modelo - no necesitas llamarlo aparte.
    
    Uso:
        modelo = BlipEspanol.from_pretrained("blip-final-5")
        caption = modelo.predict("imagen.jpg")  # ← Ya viene corregido
    """
    
    def __init__(self, model, processor, device="cpu", image_size=384, num_threads=4):
        """
        Inicializa el modelo BLIP con corrector integrado.
        
        Args:
            model: Modelo BLIP cargado
            processor: Procesador BLIP
            device: Dispositivo ("cpu" o "cuda")
            image_size: Tamaño máximo de imagen para procesamiento
            num_threads: Número de hilos para CPU
        """
        self.model = model
        self.processor = processor
        self.device = torch.device(device)
        self.image_size = image_size
        
        # Optimización CPU - solo configurar threads si no se han configurado antes
        if self.device.type == "cpu":
            try:
                torch.set_num_threads(num_threads)
                torch.set_num_interop_threads(1)
            except RuntimeError as e:
                # Si ya se configuraron los threads, ignorar el error
                if "cannot set number" not in str(e):
                    raise
                # Los threads ya están configurados, continuar
                pass

        
        # Cargar diccionarios de corrección
        print("📚 Cargando diccionario español...")
        self.correcciones = obtener_correcciones()
        self.vocabulario = obtener_vocabulario()
        print(f"✅ Diccionario cargado: {len(self.correcciones)} correcciones, {len(self.vocabulario)} palabras")
        
        # Pre-configurar opciones de generación optimizadas
        self.generation_config = {
            "max_new_tokens": 100,
            "min_new_tokens": 10,
            "num_beams": 1,        # Greedy decoding (más rápido)
            "do_sample": False,    # Determinista
            "use_cache": True,     # Usar KV cache
        }
    
    @classmethod
    def from_pretrained(cls, model_path=None, device=None, image_size=None, num_threads=None):
        """
        Carga el modelo BLIP desde disco con corrector integrado.
        
        Los parámetros se cargan desde variables de entorno (.env) si no se especifican.
        
        Args:
            model_path: Ruta al modelo guardado (default: desde .env)
            device: "cpu" o "cuda" (default: desde .env)
            image_size: Tamaño máximo de imagen (default: desde .env)
            num_threads: Hilos para CPU (default: desde .env)
        
        Returns:
            BlipEspanol: Modelo optimizado con corrector integrado
        """
        # Cargar configuración desde .env o usar valores por defecto
        if model_path is None:
            model_path = os.getenv('BLIP_MODEL_PATH', 'blip-final-5')
        if device is None:
            device = os.getenv('BLIP_DEVICE', 'cpu')
        if image_size is None:
            image_size = int(os.getenv('BLIP_IMAGE_SIZE', '384'))
        if num_threads is None:
            num_threads = int(os.getenv('BLIP_NUM_THREADS', '4'))
        
        print(f"⏳ Cargando modelo BLIP desde {model_path}...")
        
        # Cargar processor y modelo
        processor = BlipProcessor.from_pretrained(model_path)
        model = BlipForConditionalGeneration.from_pretrained(
            model_path,
            torch_dtype=torch.float32,  # Explícito para CPU
            low_cpu_mem_usage=True      # Optimizar uso de RAM
        )
        
        # Mover a device
        model.to(device)
        model.eval()
        
        # Deshabilitar gradientes para inferencia (ahorra memoria)
        for param in model.parameters():
            param.requires_grad = False
        
        # CUANTIZACIÓN INT8: Acelera 2-3x en CPU/Raspberry Pi
        print("⏳ Aplicando cuantización INT8...")
        try:
            # Usar la nueva API de cuantización (torch.ao)
            model = torch.ao.quantization.quantize_dynamic(  # type: ignore
                model,
                {torch.nn.Linear},  # Cuantizar todas las capas lineales
                dtype=torch.qint8
            )
            print("✅ Modelo cuantizado a INT8")
        except AttributeError:
            # Fallback a la API antigua si torch.ao no está disponible
            model = torch.quantization.quantize_dynamic(  # type: ignore[attr-defined]
                model,
                {torch.nn.Linear},
                dtype=torch.qint8
            )
            print("✅ Modelo cuantizado a INT8 (API legacy)")
        
        print("✅ Modelo BLIP cargado y optimizado")
        
        return cls(model, processor, device, image_size, num_threads)
    
    def _corregir_texto(self, texto):
        """
        Aplica corrección ortográfica automática al texto generado.
        
        Esta función es INTERNA - se llama automáticamente en predict().
        
        Corrige:
        - Palabras sin tildes -> palabras con tildes
        - Palabras sin eñes -> palabras con eñes
        - Errores ortográficos comunes
        
        Args:
            texto: Texto crudo generado por el modelo
        
        Returns:
            str: Texto corregido ortográficamente
        """
        # Separar palabras y puntuación
        palabras = re.findall(r'\b\w+\b|[^\w\s]', texto)
        resultado = []
        
        for palabra in palabras:
            # Solo corregir palabras alfabéticas
            if palabra.strip() and palabra.isalpha():
                palabra_lower = palabra.lower()
                
                # Buscar en diccionario de correcciones
                if palabra_lower in self.correcciones:
                    corregida = self.correcciones[palabra_lower]
                    
                    # Mantener mayúscula inicial si la tenía
                    if palabra[0].isupper():
                        corregida = corregida.capitalize()
                    
                    resultado.append(corregida)
                else:
                    # Si no está en correcciones, mantener palabra original
                    resultado.append(palabra)
            else:
                # Mantener puntuación y números tal cual
                resultado.append(palabra)
        
        # Unir palabras con espacios adecuados
        texto_corregido = ' '.join(resultado)
        
        # Limpiar espacios antes de puntuación
        texto_corregido = re.sub(r'\s+([.,;:!?])', r'\1', texto_corregido)
        
        # Capitalizar primera letra
        if texto_corregido:
            texto_corregido = texto_corregido[0].upper() + texto_corregido[1:]
        
        return texto_corregido
    
    @torch.inference_mode()
    def predict(self, image, max_new_tokens=None, num_beams=None, **kwargs):
        """
        Genera caption para una imagen CON corrección automática.
        
        Este método hace TODO el trabajo: genera el caption Y lo corrige.
        No necesitas llamar al corrector por separado.
        
        Args:
            image: PIL Image o path a la imagen
            max_new_tokens: Máximo de tokens (default: configuración interna)
            num_beams: Tamaño de beam search (default: configuración interna)
            **kwargs: Otros parámetros para generate()
        
        Returns:
            str: Caption corregido ortográficamente en español
        """
        # Si es path, cargar imagen
        if isinstance(image, str):
            image = Image.open(image)
        
        # Conversión RGB solo si es necesario
        if image.mode != "RGB":
            image = image.convert("RGB")
        
        # OPTIMIZACIÓN: Resize para reducir procesamiento
        if max(image.size) > self.image_size:
            image.thumbnail((self.image_size, self.image_size), Image.Resampling.LANCZOS)
        
        # Procesar imagen
        inputs = self.processor(images=image, return_tensors="pt")
        inputs = {k: v.to(self.device, non_blocking=True) for k, v in inputs.items()}
        
        # Combinar configuración por defecto con parámetros personalizados
        gen_config = self.generation_config.copy()
        if max_new_tokens is not None:
            gen_config["max_new_tokens"] = max_new_tokens
        if num_beams is not None:
            gen_config["num_beams"] = num_beams
        gen_config.update(kwargs)
        
        # Generar caption
        with torch.no_grad():
            out = self.model.generate(**inputs, **gen_config)
        
        # Decodificar
        caption_raw = self.processor.decode(out[0], skip_special_tokens=True).strip()
        
        # ✅ CORRECCIÓN AUTOMÁTICA (se hace internamente)
        caption_corregido = self._corregir_texto(caption_raw)
        
        return caption_corregido
    
    def generate_caption(self, image):
        """
        Alias de predict() para compatibilidad con código anterior.
        
        Args:
            image: PIL Image o path a la imagen
        
        Returns:
            str: Caption corregido en español
        """
        return self.predict(image)
    
    def __call__(self, image, **kwargs):
        """Permite usar modelo(image) directamente"""
        return self.predict(image, **kwargs)
    
    def to(self, device):
        """Mover modelo a otro device"""
        self.model.to(device)
        self.device = torch.device(device)
        return self
    
    def eval(self):
        """Modo evaluación"""
        self.model.eval()
        return self


# ============================================
# 🌍 API Global (compatibilidad con código existente)
# ============================================

_global_generator = None
_global_characteristics_generator = None

def get_global_generator():
    """
    Obtiene o crea la instancia global del generador BLIP original.
    
    Esta función mantiene compatibilidad con el código anterior,
    pero ahora usa BlipEspanol con corrección automática.
    
    Returns:
        BlipEspanol: Instancia global del modelo con corrector
    """
    global _global_generator
    if _global_generator is None:
        print("🚀 Inicializando BlipEspanol global (modelo original)...")
        # Cargar desde .env automáticamente
        _global_generator = BlipEspanol.from_pretrained()
        print("✅ BlipEspanol inicializado correctamente")
    return _global_generator

def get_global_characteristics_generator():
    """
    Obtiene o crea la instancia global del generador BLIP de características.
    
    Este modelo está entrenado específicamente para generar descripciones
    en formato: "nombre, característica1, característica2, ..."
    
    Returns:
        BlipEspanol: Instancia global del modelo de características
    """
    global _global_characteristics_generator
    if _global_characteristics_generator is None:
        print("🚀 Inicializando BlipEspanol global (modelo de características)...")
        
        # Cargar configuración desde .env
        characteristics_model_path = os.getenv('BLIP_MODEL_CARACTERISTICAS_PATH', 'blip-characteristics')
        device = os.getenv('BLIP_DEVICE', 'cpu')
        image_size = int(os.getenv('BLIP_IMAGE_SIZE', '384'))
        num_threads = int(os.getenv('BLIP_NUM_THREADS', '4'))
        
        # Cargar modelo de características
        _global_characteristics_generator = BlipEspanol.from_pretrained(
            model_path=characteristics_model_path,
            device=device,
            image_size=image_size,
            num_threads=num_threads
        )
        print("✅ BlipEspanol de características inicializado correctamente")
    return _global_characteristics_generator

def quick_generate(image: Image.Image) -> str:
    """
    Genera caption rápidamente usando la instancia global del modelo original.
    
    Función de conveniencia para generar captions sin instanciar el modelo.
    El caption viene automáticamente corregido.
    
    Args:
        image: Imagen PIL
    
    Returns:
        str: Caption corregido en español
    """
    return get_global_generator().generate_caption(image)

def quick_generate_characteristics(image: Image.Image) -> str:
    """
    Genera descripción de características usando el modelo especializado.
    
    Este modelo genera descripciones en formato:
    "nombre, característica1, característica2, característica3"
    
    Ejemplo:
        "isla, porción de tierra aislada, rodeada completamente por agua"
    
    Args:
        image: Imagen PIL
    
    Returns:
        str: Descripción en formato "nombre, característica1, característica2, ..."
    """
    return get_global_characteristics_generator().generate_caption(image)


print("✅ Módulo BlipEspanol cargado correctamente")
print("💡 Corrector ortográfico integrado automáticamente")
print("🎯 Soporte para modelo original y modelo de características")

