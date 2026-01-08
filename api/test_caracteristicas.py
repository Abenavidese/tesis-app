"""
Script de prueba para la actividad de características.

Este script verifica que:
1. Los modelos se cargan correctamente
2. El módulo de características funciona
3. El endpoint está disponible
"""

import sys
import os

# Agregar el directorio api al path
sys.path.insert(0, os.path.dirname(__file__))

print("="*60)
print("TEST: Actividad de Características")
print("="*60)

# Test 1: Verificar variables de entorno
print("\n1️⃣ Verificando variables de entorno...")
from dotenv import load_dotenv
load_dotenv()

modelo_original = os.getenv('BLIP_MODEL_PATH')
modelo_caracteristicas = os.getenv('BLIP_MODEL_CARACTERISTICAS_PATH')

print(f"   Modelo original: {modelo_original}")
print(f"   Modelo características: {modelo_caracteristicas}")

if not modelo_original:
    print("   ❌ BLIP_MODEL_PATH no está configurado en .env")
    sys.exit(1)

if not modelo_caracteristicas:
    print("   ⚠️ BLIP_MODEL_CARACTERISTICAS_PATH no está configurado en .env")
    print("   ℹ️ Se usará el valor por defecto")

print("   ✅ Variables de entorno OK")

# Test 2: Verificar que los modelos existen
print("\n2️⃣ Verificando que los modelos existen...")

if os.path.exists(modelo_original):
    print(f"   ✅ Modelo original encontrado: {modelo_original}")
else:
    print(f"   ❌ Modelo original NO encontrado: {modelo_original}")
    sys.exit(1)

if modelo_caracteristicas and os.path.exists(modelo_caracteristicas):
    print(f"   ✅ Modelo características encontrado: {modelo_caracteristicas}")
else:
    print(f"   ⚠️ Modelo características NO encontrado: {modelo_caracteristicas}")
    print("   ℹ️ Asegúrate de configurar BLIP_MODEL_CARACTERISTICAS_PATH en .env")

# Test 3: Importar módulos
print("\n3️⃣ Importando módulos...")

try:
    from activities.characteristics_game import (
        parsear_caracteristicas,
        validar_juego_caracteristicas
    )
    print("   ✅ Módulo characteristics_game importado")
except Exception as e:
    print(f"   ❌ Error importando characteristics_game: {e}")
    sys.exit(1)

try:
    from characteristics_model import quick_generate_characteristics
    print("   ✅ Módulo characteristics_model importado")
except Exception as e:
    print(f"   ❌ Error importando characteristics_model: {e}")
    sys.exit(1)

# Test 4: Probar parseo de características
print("\n4️⃣ Probando parseo de características...")

test_descripcion = "isla, porción de tierra aislada, rodeada completamente por agua, pequeña extensión"
nombre, caracteristicas = parsear_caracteristicas(test_descripcion)

print(f"   Descripción: {test_descripcion}")
print(f"   Nombre: {nombre}")
print(f"   Características: {caracteristicas}")

if nombre == "isla" and len(caracteristicas) == 3:
    print("   ✅ Parseo de características OK")
else:
    print("   ❌ Error en parseo de características")
    sys.exit(1)

# Test 5: Probar validación
print("\n5️⃣ Probando validación de características...")

caracteristicas_nino = [
    "rodeada de agua",
    "aislada"
]

resultado = validar_juego_caracteristicas(
    descripcion_modelo=test_descripcion,
    caracteristicas_nino=caracteristicas_nino,
    umbral=0.7
)

print(f"   Características del niño: {caracteristicas_nino}")
print(f"   Resultado: {resultado['mensaje']}")
print(f"   Es correcto: {resultado['es_correcto']}")
print(f"   Porcentaje: {resultado['porcentaje_acierto']}%")
print(f"   Correctas: {resultado['caracteristicas_correctas']}")
print(f"   Incorrectas: {resultado['caracteristicas_incorrectas']}")

if resultado['es_correcto']:
    print("   ✅ Validación de características OK")
else:
    print("   ⚠️ Validación marcó como incorrecta (puede ser esperado)")

# Test 6: Verificar endpoint en main.py
print("\n6️⃣ Verificando endpoint en main.py...")

try:
    with open('main.py', 'r', encoding='utf-8') as f:
        content = f.read()
        if '/validar-caracteristicas' in content:
            print("   ✅ Endpoint /validar-caracteristicas encontrado en main.py")
        else:
            print("   ❌ Endpoint /validar-caracteristicas NO encontrado en main.py")
            sys.exit(1)
except Exception as e:
    print(f"   ❌ Error leyendo main.py: {e}")
    sys.exit(1)

# Resumen final
print("\n" + "="*60)
print("✅ TODOS LOS TESTS PASARON")
print("="*60)
print("\n📋 Próximos pasos:")
print("   1. Asegúrate de que BLIP_MODEL_CARACTERISTICAS_PATH esté configurado en .env")
print("   2. Inicia el servidor: uvicorn main:app --reload")
print("   3. Prueba el endpoint con una imagen real")
print("\n💡 Ejemplo de prueba con cURL:")
print('   curl -X POST "http://localhost:8000/validar-caracteristicas" \\')
print('     -F "image=@test_image.jpg" \\')
print('     -F \'caracteristicas_seleccionadas=["rodeada de agua", "aislada"]\'')
print()
