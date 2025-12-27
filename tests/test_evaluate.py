import requests
import json

# URL del servidor
url = "http://localhost:8000/evaluate"

# Datos de prueba
data = {
    "texto_modelo": "burros en su habitat domestico: estas imagenes muestran burros, su resistencia y comportamiento tranquilo",
    "texto_nino": "estoy observando una imagen de un burro",
    "umbral": 0.6
}

print("🔄 Enviando petición a /evaluate...")
print(f"📝 Texto modelo: {data['texto_modelo']}")
print(f"🎤 Texto niño: {data['texto_nino']}")
print()

try:
    response = requests.post(url, json=data)
    
    print(f"📊 Status Code: {response.status_code}")
    print()
    
    if response.status_code == 200:
        result = response.json()
        print("✅ RESPUESTA DEL SERVIDOR:")
        print(json.dumps(result, indent=2, ensure_ascii=False))
        print()
        print(f"🎯 Mensaje: {result['mensaje']}")
        print(f"✓ Es correcta: {result['es_correcta']}")
    else:
        print("❌ ERROR:")
        print(response.text)
        
except Exception as e:
    print(f"❌ Error: {e}")
