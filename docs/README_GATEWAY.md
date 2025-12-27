# 🌐 API Gateway - Arquitectura del Sistema

## 📋 Descripción

El sistema ahora funciona con una arquitectura de **API Gateway** que separa las responsabilidades:

```
CELULAR (Flutter App)
    ↓
    ↓ HTTP Request
    ↓
API GATEWAY (gateway.py:8001)
    ↓
    ├─→ SERVIDOR ML (main.py:8000) → Procesamiento BLIP
    │   └─→ Respuesta al Gateway
    │
    └─→ ESP32 (Bluetooth) → Si respuesta correcta
    
    ↓
    ↓ HTTP Response
    ↓
CELULAR (Flutter App)
```

## 🚀 Cómo Iniciar el Sistema

### 1️⃣ Iniciar el Servidor ML (Backend con BLIP)

```bash
cd C:\Users\EleXc\Desktop\tesis_app\api
python main.py
```

- **Puerto:** 8000
- **Funciones:**
  - `/predict` - Genera captions con BLIP
  - `/evaluate` - Evalúa respuestas del niño
  - `/health` - Estado del modelo

### 2️⃣ Iniciar el API Gateway

```bash
cd C:\Users\EleXc\Desktop\tesis_app\api
python gateway.py
```

- **Puerto:** 8001
- **Funciones:**
  - Rutea peticiones del celular al servidor ML
  - Maneja comunicación Bluetooth con ESP32
  - Control centralizado del flujo

### 3️⃣ Configurar Flutter App

Cambiar la URL base en la app de Flutter para que apunte al **Gateway**:

```dart
// Antes (directo al servidor):
const String baseUrl = "http://192.168.x.x:8000";

// Ahora (a través del gateway):
const String baseUrl = "http://192.168.x.x:8001";
```

## 🔵 Configuración del ESP32

### Instalación de dependencias Bluetooth

```bash
pip install pyserial
```

### Emparejar ESP32 en Windows

1. Encender el ESP32 (debe tener código Bluetooth cargado)
2. `Configuración` → `Bluetooth` → `Agregar dispositivo`
3. Seleccionar "ESP32_TesisApp"
4. Anotar el puerto COM asignado (ej: COM5)

### Configurar puerto COM en el Gateway

Usar el endpoint `/configure_esp32`:

```bash
curl -X POST http://localhost:8001/configure_esp32 \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "port": "COM5",
    "baudrate": 115200
  }'
```

**⚠️ Cambiar COM5 por tu puerto real**

### Probar conexión ESP32

```bash
curl -X POST http://localhost:8001/test_esp32
```

## 📡 Endpoints del Gateway

### 1. POST `/predict`
Genera un caption para una imagen.

**Request:**
```bash
curl -X POST http://localhost:8001/predict \
  -F "image=@imagen.jpg"
```

**Response:**
```json
{
  "caption": "a donkey standing in a field",
  "status": "success",
  "processing_time_seconds": 0.85
}
```

---

### 2. POST `/evaluate`
Evalúa la respuesta del niño y envía señal al ESP32 si es correcta.

**Request:**
```bash
curl -X POST http://localhost:8001/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "texto_modelo": "un burro parado en un campo",
    "texto_nino": "es un burro",
    "umbral": 0.6
  }'
```

**Response (Correcta):**
```json
{
  "mensaje": "¡Felicidades, respuesta correcta!",
  "es_correcta": true,
  "esp32_signal_sent": true,
  "detalles": {
    "sujeto_modelo": "burro",
    "sujeto_nino": "burro",
    "sujeto_igual": true,
    "similitud": 0.7845,
    "umbral": 0.6
  }
}
```

**Response (Incorrecta):**
```json
{
  "mensaje": "¡Inténtalo de nuevo!",
  "es_correcta": false,
  "detalles": {
    "sujeto_modelo": "burro",
    "sujeto_nino": "caballo",
    "sujeto_igual": false,
    "similitud": 0.0,
    "umbral": 0.6
  }
}
```

---

### 3. GET `/health`
Verifica el estado del sistema completo.

**Response:**
```json
{
  "gateway_status": "healthy",
  "ml_server_status": "healthy",
  "esp32_enabled": true,
  "esp32_port": "COM5"
}
```

---

### 4. POST `/configure_esp32`
Configura la conexión con el ESP32.

**Request:**
```json
{
  "enabled": true,
  "port": "COM5",
  "baudrate": 115200
}
```

---

### 5. POST `/test_esp32`
Envía una señal de prueba al ESP32.

---

## 🔌 Código Arduino ESP32

```cpp
// Ejemplo básico para recibir señales Bluetooth
void setup() {
  Serial.begin(115200);
  // Configurar Bluetooth aquí
}

void loop() {
  if (Serial.available()) {
    char received = Serial.read();
    
    if (received == 'b') {
      // ¡Respuesta correcta!
      // Activar LED, motor, buzzer, etc.
      digitalWrite(LED_PIN, HIGH);
      delay(1000);
      digitalWrite(LED_PIN, LOW);
    }
    else if (received == 't') {
      // Señal de prueba
      Serial.println("Test signal received!");
    }
  }
}
```

## 🔧 Flujo de Datos Detallado

### Flujo `/predict`:
1. 📱 Celular envía imagen → Gateway (8001)
2. 🌐 Gateway reenvía → Servidor ML (8000)
3. 🤖 BLIP procesa imagen → genera caption
4. 📤 Servidor ML → Gateway → Celular

### Flujo `/evaluate`:
1. 📱 Celular envía textos → Gateway (8001)
2. 🌐 Gateway reenvía → Servidor ML (8000)
3. 🧠 Evaluador compara textos → resultado
4. 📤 Servidor ML → Gateway
5. 🔵 **Si es correcta:** Gateway → ESP32 (Bluetooth: 'b')
6. 📤 Gateway → Celular

## 📝 Cambios Realizados

### ✅ Eliminado de main.py:
- ❌ Todo el código de Vosk
- ❌ Endpoint `/speech-to-text`
- ❌ Funciones de procesamiento de audio
- ❌ Imports: `wave`, `tempfile`, `json`, `os`

### ✅ Creado gateway.py:
- ✅ Proxy para `/predict`
- ✅ Proxy para `/evaluate` con control ESP32
- ✅ Gestión de conexión Bluetooth
- ✅ Endpoints de configuración y prueba

## 🎯 Ventajas de esta Arquitectura

1. **Separación de responsabilidades:**
   - `main.py` → Solo ML (BLIP + Evaluador)
   - `gateway.py` → Ruteo + ESP32 + Lógica de negocio

2. **Escalabilidad:**
   - Fácil agregar más servidores ML
   - Load balancing futuro

3. **Mantenibilidad:**
   - Código más limpio y modular
   - Fácil testing individual

4. **Seguridad:**
   - Gateway puede agregar autenticación
   - Servidor ML no expuesto directamente

## 🐛 Troubleshooting

### El Gateway no puede conectar al servidor ML
```bash
# Verifica que main.py esté corriendo en puerto 8000
curl http://localhost:8000/health
```

### ESP32 no recibe señales
1. Verifica que `bleak` esté instalado: `pip install bleak`
2. Verifica la dirección MAC del ESP32
3. Asegúrate de que el ESP32 esté en modo pairable
4. Usa `/test_esp32` para probar la conexión

### El celular no puede conectar al Gateway
1. Verifica que ambos estén en la misma red
2. Usa la IP correcta del PC (no localhost)
3. Verifica el firewall de Windows
4. Prueba con: `curl http://192.168.x.x:8001/ping`

## 📚 Próximos Pasos

1. ✅ Sistema base funcionando
2. 🔄 Configurar ESP32 real
3. 🔄 Actualizar Flutter app para usar Gateway
4. 🔄 Testing completo del flujo
5. 🔄 Agregar logs más detallados
6. 🔄 Considerar autenticación/seguridad
