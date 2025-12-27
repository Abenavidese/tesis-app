#!/usr/bin/env python3
"""
Script simple para probar que el modelo BLIP se puede cargar
"""
import sys
import os

# Agregar el directorio actual al path
sys.path.insert(0, os.path.dirname(__file__))

def test_model_loading():
    print("🔍 Probando carga del modelo BLIP...")
    
    try:
        print("📦 Importando módulo BLIP...")
        from blip.generation import get_global_generator
        
        print("⏳ Cargando modelo (esto puede tardar 1-3 minutos)...")
        generator = get_global_generator()
        
        print("✅ Modelo cargado exitosamente!")
        print(f"📄 Tipo: {type(generator)}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Error de importación: {e}")
        return False
    except Exception as e:
        print(f"❌ Error cargando modelo: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Test de Carga del Modelo BLIP")
    print("=" * 50)
    
    success = test_model_loading()
    
    print("\n" + "=" * 50)
    if success:
        print("🎉 Modelo carga correctamente!")
        print("✨ El servidor debería funcionar sin problemas")
    else:
        print("⚠️ Hay problemas con la carga del modelo")
        print("💡 Verifica:")
        print("   - Que las dependencias estén instaladas")
        print("   - Que el modelo esté en la carpeta blip-final-5/")
        print("   - Que tengas suficiente RAM disponible")