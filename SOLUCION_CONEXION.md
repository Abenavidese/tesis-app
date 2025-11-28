# 🔧 Solución: Flutter no Encuentra el Servidor

## 🔍 El Problema
Tu servidor FastAPI está corriendo perfectamente en `http://127.0.0.1:8000/`, pero Flutter dice que no lo encuentra. Esto es común y tiene solución fácil.

## 🎯 Causa Principal
**La URL `127.0.0.1` solo funciona desde la misma máquina.** Dependiendo de dónde ejecutes Flutter, necesitas una URL diferente:

- 📱 **Emulador Android** → `http://10.0.2.2:8000`
- 💻 **Web/Desktop** → `http://127.0.0.1:8000`
- 🍎 **iOS Simulator** → `http://localhost:8000`
- 📲 **Dispositivo Real** → `http://[TU_IP_WIFI]:8000`

## ✅ Solución Rápida

### **Paso 1: Identifica tu Entorno**
¿Dónde estás ejecutando Flutter?
- `flutter run` → Probablemente emulador Android
- `flutter run -d chrome` → Web (usa 127.0.0.1)
- `flutter run -d windows` → Desktop (usa 127.0.0.1)

### **Paso 2: Usa la App para Probar**
1. **Ejecuta tu app Flutter**
2. **Presiona el botón "Debug API"** (botón 3)
3. **Prueba cada URL** hasta que una funcione
4. **Cuando veas "✅ CONECTADO!"**, usa esa URL

### **Paso 3: Configura la URL Correcta**
En `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // Usa la que funcionó
```

## 🚀 Método Automático

### **Obtener tu IP WiFi:**
```bash
cd api
python get_ips.py
```

### **Probar desde la App:**
1. Abre la app Flutter
2. Toca "Debug API" 
3. Prueba cada URL hasta encontrar la correcta

## 📋 URLs más Comunes

### **Para Emulador Android (PRUEBA ESTA PRIMERO):**
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

### **Para Web/Desktop:**
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

### **Para Dispositivo Real:**
1. Ejecuta: `python get_ips.py`
2. Usa la IP WiFi que te muestre
3. Ejemplo: `http://192.168.1.100:8000`

## 🔧 Verificación

### **1. Servidor Funcionando:**
- ✅ `http://127.0.0.1:8000/` → Se abre en navegador
- ✅ Muestra: "API de BLIP funcionando..."

### **2. Flutter Conectando:**
- 📱 App abre sin errores
- 🔗 Botón "Debug API" muestra "✅ CONECTADO!"
- 📸 Puedes tomar fotos y recibir descripciones

## 🎯 Solución Más Probable

**Si estás usando emulador Android**, cambia esto en `api_constants.dart`:

```dart
// CAMBIAR ESTO:
static const String baseUrl = 'http://127.0.0.1:8000';

// POR ESTO:
static const String baseUrl = 'http://10.0.2.2:8000';
```

¡Esa es la solución en el 90% de los casos! 🎉

## 🆘 Si Sigue sin Funcionar

1. **Verifica tu firewall** (Windows Defender)
2. **Reinicia el servidor** con IP específica:
   ```bash
   python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
3. **Usa la función Debug** en la app para probar todas las URLs
4. **Verifica que estés en la misma red WiFi** (dispositivo real)

La app ahora tiene una función de debug integrada que te ayudará a encontrar la URL correcta automáticamente. ¡Úsala! 🚀