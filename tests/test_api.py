#!/usr/bin/env python3
"""
Script para probar la API de BLIP antes de usar con Flutter
"""
import requests
import time
from PIL import Image
import io
import sys
import os

# Agregar el directorio actual al path para imports
sys.path.insert(0, os.path.dirname(__file__))

def test_api():
    base_url = "http://127.0.0.1:8000"
    
    print("🔍 Probando API de BLIP...")
    
    # 1. Probar endpoint root
    try:
        response = requests.get(f"{base_url}/")
        print(f"✅ Root endpoint: {response.status_code}")
        print(f"   Respuesta: {response.json()}")
    except Exception as e:
        print(f"❌ Error en root endpoint: {e}")
        return False
    
    # 2. Probar health check
    try:
        response = requests.get(f"{base_url}/health")
        print(f"✅ Health check: {response.status_code}")
        health_data = response.json()
        print(f"   Modelo cargado: {health_data.get('model_loaded', False)}")
    except Exception as e:
        print(f"❌ Error en health check: {e}")
    
    # 3. Crear una imagen de prueba
    print("\n📷 Creando imagen de prueba...")
    test_image = Image.new('RGB', (100, 100), color='red')
    img_byte_arr = io.BytesIO()
    test_image.save(img_byte_arr, format='JPEG')
    img_byte_arr.seek(0)
    
    # 4. Probar predicción
    try:
        print("🤖 Enviando imagen para predicción...")
        start_time = time.time()
        
        files = {'image': ('test.jpg', img_byte_arr, 'image/jpeg')}
        response = requests.post(f"{base_url}/predict", files=files, timeout=180)
        
        processing_time = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Predicción exitosa en {processing_time:.2f}s")
            print(f"   Caption: {data.get('caption', 'N/A')}")
            print(f"   Tiempo del servidor: {data.get('processing_time_seconds', 'N/A')}s")
            return True
        else:
            print(f"❌ Error en predicción: {response.status_code}")
            print(f"   Detalle: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Timeout en predicción (>3 minutos)")
        print("   La primera vez puede tardar más mientras carga el modelo")
        return False
    except Exception as e:
        print(f"❌ Error en predicción: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Test de API BLIP")
    print("=" * 50)
    
    success = test_api()
    
    print("\n" + "=" * 50)
    if success:
        print("🎉 API funcionando correctamente!")
        print("✨ Ya puedes usar la app Flutter")
    else:
        print("⚠️ Hay problemas con la API")
        print("💡 Verifica que el servidor esté ejecutándose:")
        print("   cd api && python -m uvicorn main:app --reload")