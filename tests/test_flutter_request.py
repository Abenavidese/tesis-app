#!/usr/bin/env python3
"""
Script para probar el envío de imágenes como lo hace Flutter
"""
import requests
from PIL import Image
import io
import tempfile
import os

def test_flutter_like_request():
    """Simula exactamente como Flutter envía las imágenes"""
    base_url = "http://127.0.0.1:8000"
    
    print("🧪 Probando envío de imagen como Flutter...")
    
    # Crear una imagen de prueba
    test_image = Image.new('RGB', (100, 100), color='blue')
    
    # Guardar en archivo temporal (como hace Flutter)
    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
        test_image.save(temp_file.name, 'JPEG')
        temp_path = temp_file.name
    
    try:
        print(f"📁 Imagen guardada en: {temp_path}")
        
        # Enviar como multipart form (igual que Flutter)
        with open(temp_path, 'rb') as f:
            files = {
                'image': (
                    os.path.basename(temp_path),  # filename
                    f,                           # file object
                    'image/jpeg'                 # content type
                )
            }
            
            headers = {
                'Accept': 'application/json'
            }
            
            print("📤 Enviando petición POST...")
            response = requests.post(
                f"{base_url}/predict", 
                files=files,
                headers=headers,
                timeout=30
            )
            
        print(f"📥 Status: {response.status_code}")
        print(f"📄 Respuesta: {response.text}")
        
        if response.status_code == 200:
            print("✅ ¡Éxito! La imagen se procesó correctamente")
            data = response.json()
            print(f"🤖 Caption: {data.get('caption', 'N/A')}")
        else:
            print(f"❌ Error {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error en la petición: {e}")
    finally:
        # Limpiar archivo temporal
        if os.path.exists(temp_path):
            os.unlink(temp_path)

def test_ping():
    """Probar conectividad básica"""
    try:
        response = requests.get("http://127.0.0.1:8000/ping", timeout=5)
        if response.status_code == 200:
            print("✅ Servidor responde correctamente")
            return True
        else:
            print(f"⚠️ Servidor responde con código: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ No se puede conectar al servidor: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Test de Conexión Flutter → FastAPI")
    print("=" * 50)
    
    # Probar conectividad básica
    if test_ping():
        print("\n🧪 Probando envío de imagen...")
        test_flutter_like_request()
    else:
        print("\n💡 Solución:")
        print("1. Verifica que el servidor esté corriendo:")
        print("   python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000")
        print("2. Asegúrate de que no haya firewall bloqueando el puerto 8000")