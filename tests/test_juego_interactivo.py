"""
Script de prueba para el endpoint /validar-reto
"""
import requests
import sys

def test_validar_reto(imagen_path: str, sujeto_solicitado: str, umbral: float = 0.7):
    """
    Prueba el endpoint /validar-reto con una imagen y un sujeto solicitado.
    """
    url = "http://localhost:8000/validar-reto"
    
    print(f"\n{'='*60}")
    print(f"🎮 PRUEBA DE RETO INTERACTIVO")
    print(f"{'='*60}")
    print(f"📸 Imagen: {imagen_path}")
    print(f"🎯 Sujeto solicitado: '{sujeto_solicitado}'")
    print(f"📊 Umbral: {umbral}")
    print(f"{'='*60}\n")
    
    try:
        # Enviar request
        with open(imagen_path, "rb") as f:
            files = {"image": f}
            data = {
                "sujeto_solicitado": sujeto_solicitado,
                "umbral": str(umbral)
            }
            
            print("⏳ Enviando request al servidor...")
            response = requests.post(url, files=files, data=data)
            response.raise_for_status()
            
            result = response.json()
        
        # Mostrar resultados
        print("\n" + "="*60)
        print("📋 RESULTADO")
        print("="*60)
        
        if result["es_correcto"]:
            print("✅ ¡CORRECTO! 🎉")
        else:
            print("❌ INCORRECTO")
        
        print(f"\n📝 Detalles:")
        print(f"   • Sujeto solicitado: {result['sujeto_solicitado']}")
        print(f"   • Sujeto detectado:  {result['sujeto_detectado']}")
        print(f"   • Similitud:         {result['similitud']:.4f}")
        print(f"   • Umbral:            {result['umbral']}")
        print(f"   • Tiempo:            {result['processing_time_seconds']:.2f}s")
        
        print(f"\n📄 Descripción completa:")
        print(f"   {result['descripcion_completa']}")
        
        print(f"\n💬 Mensaje: {result['mensaje']}")
        print("="*60 + "\n")
        
        return result
        
    except FileNotFoundError:
        print(f"❌ Error: No se encontró la imagen '{imagen_path}'")
        sys.exit(1)
    except requests.exceptions.ConnectionError:
        print("❌ Error: No se pudo conectar al servidor.")
        print("   Asegúrate de que el servidor esté corriendo en http://localhost:8000")
        sys.exit(1)
    except requests.exceptions.HTTPError as e:
        print(f"❌ Error HTTP: {e}")
        print(f"   Respuesta del servidor: {response.text}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


def test_multiple():
    """
    Prueba múltiples casos del juego interactivo.
    """
    print("\n" + "="*60)
    print("🎮 SUITE DE PRUEBAS - JUEGO INTERACTIVO")
    print("="*60)
    
    # Lista de pruebas
    # Formato: (imagen, sujeto_esperado, descripcion)
    tests = [
        # Estos son ejemplos - reemplaza con tus imágenes reales
        # ("test_images/caballo.jpg", "caballo", "Reto 1: Identificar caballo"),
        # ("test_images/burro.jpg", "burro", "Reto 2: Captura rápida de burro"),
        # ("test_images/leon.jpg", "león", "Reto 3: Identificar león"),
    ]
    
    if not tests:
        print("\n⚠️  No hay tests configurados.")
        print("   Edita este archivo y agrega tus imágenes de prueba en la lista 'tests'")
        print("\n   Ejemplo:")
        print("   tests = [")
        print('       ("test_images/caballo.jpg", "caballo", "Test 1"),')
        print('       ("test_images/burro.jpg", "burro", "Test 2"),')
        print("   ]")
        return
    
    resultados = []
    
    for i, (imagen, sujeto, descripcion) in enumerate(tests, 1):
        print(f"\n📌 TEST {i}/{len(tests)}: {descripcion}")
        resultado = test_validar_reto(imagen, sujeto)
        resultados.append((descripcion, resultado["es_correcto"]))
    
    # Resumen
    print("\n" + "="*60)
    print("📊 RESUMEN DE TESTS")
    print("="*60)
    
    correctos = sum(1 for _, correcto in resultados if correcto)
    total = len(resultados)
    
    for desc, correcto in resultados:
        emoji = "✅" if correcto else "❌"
        print(f"{emoji} {desc}")
    
    print(f"\n🎯 Resultado: {correctos}/{total} correctos ({correctos/total*100:.1f}%)")
    print("="*60 + "\n")


if __name__ == "__main__":
    # Si se pasan argumentos, hacer prueba individual
    if len(sys.argv) >= 3:
        imagen = sys.argv[1]
        sujeto = sys.argv[2]
        umbral = float(sys.argv[3]) if len(sys.argv) > 3 else 0.7
        
        test_validar_reto(imagen, sujeto, umbral)
    
    # Si no hay argumentos, mostrar ayuda
    else:
        print("\n" + "="*60)
        print("🎮 TEST DE JUEGO INTERACTIVO")
        print("="*60)
        print("\nUso:")
        print("  python test_juego_interactivo.py <imagen> <sujeto> [umbral]")
        print("\nEjemplos:")
        print("  python test_juego_interactivo.py foto_caballo.jpg caballo")
        print("  python test_juego_interactivo.py foto_burro.jpg burro 0.8")
        print("\nPara ejecutar múltiples tests:")
        print("  1. Edita este archivo y agrega tus imágenes en la función test_multiple()")
        print("  2. Ejecuta: python test_juego_interactivo.py")
        print("="*60 + "\n")
