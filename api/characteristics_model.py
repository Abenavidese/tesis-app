# characteristics_model.py - Modelo de generación de características
"""
Módulo para generar características de imágenes usando BLIP.

Este módulo es un wrapper que usa el modelo BLIP de características
cargado en blip/generation.py.

El modelo genera descripciones en formato:
"nombre, característica1, característica2, característica3"

Ejemplo:
    "isla, porción de tierra aislada, rodeada completamente por agua"
"""

from PIL import Image
from blip.generation import quick_generate_characteristics as _quick_generate_characteristics
from blip.generation import get_global_characteristics_generator


def quick_generate_characteristics(image: Image.Image) -> str:
    """
    Genera descripción de características para una imagen.
    
    Este modelo genera descripciones en formato:
    "nombre, característica1, característica2, característica3"
    
    Args:
        image: Imagen PIL
    
    Returns:
        Descripción en formato "nombre, característica1, característica2, ..."
    
    Ejemplo:
        >>> from PIL import Image
        >>> img = Image.open("isla.jpg")
        >>> descripcion = quick_generate_characteristics(img)
        >>> print(descripcion)
        "isla, porción de tierra aislada, rodeada completamente por agua"
    """
    return _quick_generate_characteristics(image)


# ============================================
# TESTING
# ============================================

if __name__ == "__main__":
    print("\n" + "="*60)
    print("TEST: Modelo de Características")
    print("="*60)
    
    # Crear imagen de prueba
    test_image = Image.new('RGB', (224, 224), color='blue')
    
    # Generar características
    print("\n⏳ Generando características...")
    descripcion = quick_generate_characteristics(test_image)
    
    print(f"\n✅ Descripción generada:")
    print(f"   {descripcion}")
    
    # Parsear características
    from activities.characteristics_game import parsear_caracteristicas
    nombre, caracteristicas = parsear_caracteristicas(descripcion)
    
    print(f"\n📋 Parseado:")
    print(f"   Nombre: {nombre}")
    print(f"   Características:")
    for i, carac in enumerate(caracteristicas, 1):
        print(f"     {i}. {carac}")

