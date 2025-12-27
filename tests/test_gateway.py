# test_gateway.py - Script para probar el API Gateway
import requests
import time
from pathlib import Path
import sys

# Agregar carpeta padre al path si es necesario
sys.path.insert(0, str(Path(__file__).parent.parent))

GATEWAY_URL = "http://localhost:8001"
ML_SERVER_URL = "http://localhost:8000"

def print_header(text):
    print("\n" + "="*60)
    print(f"  {text}")
    print("="*60)

def test_ping():
    """Prueba conectividad básica"""
    print_header("1️⃣ TEST: Ping Gateway")
    try:
        response = requests.get(f"{GATEWAY_URL}/ping", timeout=5)
        print(f"✅ Gateway responde: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_health():
    """Verifica estado del sistema"""
    print_header("2️⃣ TEST: Health Check")
    try:
        response = requests.get(f"{GATEWAY_URL}/health", timeout=5)
        data = response.json()
        print(f"Gateway Status: {data.get('gateway_status')}")
        print(f"ML Server Status: {data.get('ml_server_status')}")
        print(f"ESP32 Enabled: {data.get('esp32_enabled')}")
        return data.get('ml_server_status') == 'healthy'
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_predict():
    """Prueba generación de captions"""
    print_header("3️⃣ TEST: Predict (Caption Generation)")
    
    # Buscar una imagen de prueba
    test_images = [
        Path("test_image.jpg"),
        Path("test_image.png"),
        Path("../test.jpg"),
        Path("test.jpg")
    ]
    
    image_path = None
    for img in test_images:
        if img.exists():
            image_path = img
            break
    
    if not image_path:
        print("⚠️ No se encontró imagen de prueba. Crea 'test_image.jpg' para probar.")
        print("💡 Este test es opcional - el sistema funciona sin él")
        return None  # No es un fallo, solo se salta
    
    try:
        with open(image_path, 'rb') as f:
            files = {'image': f}
            print(f"📤 Enviando {image_path} al Gateway...")
            start = time.time()
            response = requests.post(f"{GATEWAY_URL}/predict", files=files, timeout=30)
            elapsed = time.time() - start
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Caption generado en {elapsed:.2f}s:")
                print(f"   '{data.get('caption')}'")
                return True
            else:
                print(f"❌ Error {response.status_code}: {response.text}")
                return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_evaluate_correct():
    """Prueba evaluación con respuesta correcta"""
    print_header("4️⃣ TEST: Evaluate (Respuesta Correcta)")
    
    payload = {
        "texto_modelo": "un burro parado en un campo",
        "texto_nino": "es un burro",
        "umbral": 0.6
    }
    
    try:
        print(f"📤 Modelo: {payload['texto_modelo']}")
        print(f"📤 Niño: {payload['texto_nino']}")
        
        start = time.time()
        response = requests.post(
            f"{GATEWAY_URL}/evaluate",
            json=payload,
            timeout=10
        )
        elapsed = time.time() - start
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n⏱️ Tiempo: {elapsed:.2f}s")
            print(f"{'✅' if data['es_correcta'] else '❌'} {data['mensaje']}")
            print(f"📊 Similitud: {data['detalles']['similitud']:.4f}")
            print(f"🔵 ESP32 Signal Sent: {data.get('esp32_signal_sent', 'N/A')}")
            return data['es_correcta']
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_evaluate_incorrect():
    """Prueba evaluación con respuesta incorrecta"""
    print_header("5️⃣ TEST: Evaluate (Respuesta Incorrecta)")
    
    payload = {
        "texto_modelo": "un burro parado en un campo",
        "texto_nino": "es un caballo",
        "umbral": 0.6
    }
    
    try:
        print(f"📤 Modelo: {payload['texto_modelo']}")
        print(f"📤 Niño: {payload['texto_nino']}")
        
        start = time.time()
        response = requests.post(
            f"{GATEWAY_URL}/evaluate",
            json=payload,
            timeout=10
        )
        elapsed = time.time() - start
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n⏱️ Tiempo: {elapsed:.2f}s")
            print(f"{'✅' if data['es_correcta'] else '❌'} {data['mensaje']}")
            print(f"📊 Similitud: {data['detalles']['similitud']:.4f}")
            return not data['es_correcta']  # Debe ser incorrecta
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("\n🧪 TEST SUITE - API GATEWAY")
    print("="*60)
    print(f"Gateway URL: {GATEWAY_URL}")
    print(f"ML Server URL: {ML_SERVER_URL}")
    
    results = []
    
    # Ejecutar tests
    results.append(("Ping", test_ping()))
    time.sleep(0.5)
    
    results.append(("Health Check", test_health()))
    time.sleep(0.5)
    
    predict_result = test_predict()
    if predict_result is not None:  # Si hay imagen para probar
        results.append(("Predict", predict_result))
        time.sleep(0.5)
    
    results.append(("Evaluate (Correcta)", test_evaluate_correct()))
    time.sleep(0.5)
    
    results.append(("Evaluate (Incorrecta)", test_evaluate_incorrect()))
    
    # Resumen
    print_header("📋 RESUMEN")
    passed = 0
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 Total: {passed}/{len(results)} tests pasaron")
    
    if passed == len(results):
        print("🎉 ¡Todos los tests pasaron!")
    else:
        print("⚠️ Algunos tests fallaron. Revisa los logs arriba.")

if __name__ == "__main__":
    main()
