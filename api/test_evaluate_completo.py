import requests
import json

# URL del servidor
url = "http://localhost:8000/evaluate"

print("=" * 60)
print("PRUEBA 1: Respuesta CORRECTA")
print("=" * 60)

data1 = {
    "texto_modelo": "un burro en el campo",
    "texto_nino": "veo un burro",
    "umbral": 0.6
}

response1 = requests.post(url, json=data1)
result1 = response1.json()
print(f"🎯 {result1['mensaje']}")
print(f"✓ Es correcta: {result1['es_correcta']}")
print(f"📊 Similitud: {result1['detalles']['similitud']}")
print()

print("=" * 60)
print("PRUEBA 2: Respuesta INCORRECTA (sujeto diferente)")
print("=" * 60)

data2 = {
    "texto_modelo": "un burro en el campo",
    "texto_nino": "veo un caballo",
    "umbral": 0.6
}

response2 = requests.post(url, json=data2)
result2 = response2.json()
print(f"🎯 {result2['mensaje']}")
print(f"✓ Es correcta: {result2['es_correcta']}")
print(f"📊 Sujeto modelo: {result2['detalles']['sujeto_modelo']}")
print(f"📊 Sujeto niño: {result2['detalles']['sujeto_nino']}")
print()

print("=" * 60)
print("PRUEBA 3: Respuesta INCORRECTA (similitud baja)")
print("=" * 60)

data3 = {
    "texto_modelo": "un burro comiendo pasto en el campo con otros animales",
    "texto_nino": "un burro",
    "umbral": 0.8  # Umbral más alto
}

response3 = requests.post(url, json=data3)
result3 = response3.json()
print(f"🎯 {result3['mensaje']}")
print(f"✓ Es correcta: {result3['es_correcta']}")
print(f"📊 Similitud: {result3['detalles']['similitud']} (umbral: {result3['detalles']['umbral']})")
print()

print("✅ TODAS LAS PRUEBAS COMPLETADAS")
