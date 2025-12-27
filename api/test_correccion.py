"""
Script de prueba para validar la corrección ortográfica integrada en BlipEspanol
"""

from blip.generation import BlipEspanol
from PIL import Image
import sys

def test_correccion():
    """Prueba el corrector ortográfico interno"""
    
    print("=" * 60)
    print("🧪 TEST: CORRECTOR ORTOGRÁFICO INTEGRADO")
    print("=" * 60)
    
    # Crear instancia del modelo
    print("\n1️⃣ Cargando modelo BlipEspanol...")
    modelo = BlipEspanol.from_pretrained(
        model_path="blip-final-5",
        device="cpu",
        num_threads=4,
        image_size=384
    )
    print("✅ Modelo cargado correctamente\n")
    
    # Probar corrector manualmente
    print("2️⃣ Probando corrector interno...")
    textos_prueba = [
        "un nino pequeno jugando en el jardin",
        "una montana con arboles y pajaros",
        "telefono movil sobre una mesa de cafe",
        "habitacion con television y sillon",
        "un perro marron en la playa con agua azul"
    ]
    
    print("\n📝 Ejemplos de corrección:")
    print("-" * 60)
    for texto in textos_prueba:
        corregido = modelo._corregir_texto(texto)
        print(f"ANTES:  {texto}")
        print(f"DESPUÉS: {corregido}")
        print()
    
    print("=" * 60)
    print("✅ Test de corrección completado\n")
    
    # Probar con imagen real si se proporciona
    if len(sys.argv) > 1:
        image_path = sys.argv[1]
        print(f"3️⃣ Probando con imagen: {image_path}")
        try:
            caption = modelo.predict(image_path)
            print(f"📸 Caption generado: {caption}")
            print("✅ Caption generado con corrección automática")
        except Exception as e:
            print(f"❌ Error al procesar imagen: {e}")
    else:
        print("💡 Tip: Ejecuta con 'python test_correccion.py imagen.jpg' para probar con una imagen real")

if __name__ == "__main__":
    test_correccion()
