# 📁 Estructura del Proyecto - Tesis App

## 🗂️ Organización de Carpetas

```
tesis_app/
│
├── 📂 api/                           # SERVIDOR ML (PC con el modelo BLIP)
│   ├── main.py                       # FastAPI servidor con BLIP
│   ├── evaluador.py                  # Lógica de evaluación de respuestas
│   ├── get_ips.py                    # Utilidad para obtener IPs
│   ├── test.py                       # Test básico
│   ├── .venv311/                     # Entorno virtual Python 3.11
│   ├── blip/                         # Módulo BLIP
│   ├── blip-final-5/                 # Modelo BLIP entrenado
│   └── __pycache__/
│
├── 📂 gateway/                       # API GATEWAY (Dispositivo separado)
│   ├── gateway.py                    # FastAPI Gateway principal
│   ├── requirements.txt              # Dependencias del gateway
│   ├── README.md                     # Instrucciones de instalación
│   └── venv/                         # Entorno virtual propio (crear)
│
├── 📂 docs/                          # DOCUMENTACIÓN
│   ├── ARQUITECTURA.md               # Diagramas y arquitectura completa
│   ├── README_GATEWAY.md             # Documentación del Gateway
│   ├── INICIO_RAPIDO.md              # Guía de inicio rápido
│   ├── ESP32_BLUETOOTH_SIMPLE.md     # Configurar ESP32 con Bluetooth Serial
│   ├── ESP32_SETUP.md                # Configuración detallada ESP32
│   ├── COMANDOS_RAPIDOS.md           # Cheat sheet de comandos
│   └── CHANGELOG_BLUETOOTH.md        # Cambios en comunicación Bluetooth
│
├── 📂 ejecutables/                   # SCRIPTS DE INICIO (.bat)
│   ├── start_all.bat                 # Inicia todo el sistema
│   ├── start_ml_server.bat           # Solo servidor ML
│   └── start_gateway.bat             # Solo gateway
│
├── 📂 tests/                         # TESTS Y PRUEBAS
│   ├── test_gateway.py               # Suite de tests del gateway
│   ├── test_esp32_serial.py          # Test de comunicación con ESP32
│   ├── test_api.py                   # Tests del servidor ML
│   ├── test_evaluate.py              # Tests del evaluador
│   ├── test_evaluate_completo.py     # Tests completos
│   ├── test_flutter_request.py       # Tests de peticiones desde Flutter
│   └── test_model.py                 # Tests del modelo BLIP
│
├── 📂 Aplication_Tesis/              # APP FLUTTER (Celular)
│   └── ...                           # Código de la aplicación móvil
│
└── 📂 ModeloComparacion/             # COMPARACIÓN DE MODELOS
    └── ...                           # Scripts de evaluación

```

---

## 🎯 Descripción de Componentes

### 1️⃣ **api/** - Servidor ML

**Ubicación:** PC con GPU/CPU potente para BLIP

**Función:** 
- Ejecuta el modelo BLIP para generar captions
- Evalúa respuestas usando sentence-transformers y spaCy
- Solo procesamiento de ML

**Puerto:** 8000

**Archivos principales:**
- `main.py` - Servidor FastAPI con endpoints `/predict` y `/evaluate`
- `evaluador.py` - Lógica de comparación semántica
- `blip/` - Código del modelo BLIP
- `blip-final-5/` - Modelo entrenado (>2GB)

**Iniciar:**
```bash
cd ejecutables
start_ml_server.bat
```

---

### 2️⃣ **gateway/** - API Gateway

**Ubicación:** Dispositivo separado (puede ser otro PC, Raspberry Pi, etc.)

**Función:**
- Recibe peticiones del celular
- Enruta al servidor ML
- Controla ESP32 por Bluetooth Serial
- Decide cuándo enviar señal al ESP32

**Puerto:** 8001

**Archivos principales:**
- `gateway.py` - Gateway FastAPI con proxy y control ESP32
- `requirements.txt` - Dependencias ligeras (sin PyTorch)
- `README.md` - Instrucciones específicas del gateway

**Ventajas de tenerlo separado:**
- ✅ El dispositivo con el modelo no necesita Bluetooth
- ✅ Gateway puede ser más ligero (Raspberry Pi, mini PC)
- ✅ Fácil escalar agregando más servidores ML
- ✅ Separación de responsabilidades

**Iniciar:**
```bash
cd ejecutables
start_gateway.bat
```

---

### 3️⃣ **docs/** - Documentación

**Contenido:**
- Guías de instalación y configuración
- Diagramas de arquitectura
- Documentación de APIs
- Troubleshooting

**Archivos clave:**
- `INICIO_RAPIDO.md` - Empieza aquí
- `ARQUITECTURA.md` - Entender el sistema
- `ESP32_BLUETOOTH_SIMPLE.md` - Configurar hardware
- `COMANDOS_RAPIDOS.md` - Cheat sheet

---

### 4️⃣ **ejecutables/** - Scripts de Inicio

**Contenido:**
Scripts .bat para Windows para iniciar los servicios fácilmente.

**Archivos:**
- `start_all.bat` - Inicia ML Server + Gateway (2 ventanas)
- `start_ml_server.bat` - Solo servidor ML
- `start_gateway.bat` - Solo gateway

**Uso:**
```bash
cd ejecutables
start_all.bat
```

---

### 5️⃣ **tests/** - Suite de Pruebas

**Contenido:**
Scripts de prueba para cada componente del sistema.

**Archivos principales:**
- `test_gateway.py` - Test completo del gateway
- `test_esp32_serial.py` - Prueba comunicación Bluetooth
- `test_api.py` - Tests del servidor ML
- `test_evaluate.py` - Tests del evaluador

**Ejecutar tests:**
```bash
cd tests
python test_gateway.py
python test_esp32_serial.py
```

---

## 🔄 Flujo de Datos

```
📱 CELULAR (Flutter App)
    ↓
    ↓ HTTP Request (192.168.x.x:8001)
    ↓
🌐 GATEWAY (gateway/)
    ↓                           ↓
    ↓ (192.168.x.x:8000)       ↓ (Bluetooth COM5)
    ↓                           ↓
🤖 SERVIDOR ML (api/)       🔵 ESP32
    └─ BLIP Model              └─ LED + Buzzer
    └─ Evaluador
```

---

## 🚀 Inicio Rápido por Componente

### Servidor ML (api/)
```bash
cd api
.venv311\Scripts\activate
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

### Gateway (gateway/)
```bash
cd gateway
venv\Scripts\activate  # o crear venv primero
python gateway.py
```

### Tests
```bash
cd tests
python test_gateway.py
```

---

## 📦 Dependencias por Componente

### Servidor ML (api/)
- **Pesadas:** PyTorch, Transformers, BLIP
- **Python:** 3.11.9
- **Tamaño:** ~5GB con modelo

### Gateway (gateway/)
- **Ligeras:** FastAPI, httpx, pyserial
- **Python:** 3.11+
- **Tamaño:** ~50MB

### Tests (tests/)
- **Usa:** requests, pytest (opcional)
- **Python:** 3.11+

---

## 🔧 Configuración para Producción

### Si Gateway y ML Server están en dispositivos diferentes:

1. **En el Gateway (gateway.py):**
   ```python
   MODEL_SERVER_URL = "http://IP_DEL_SERVIDOR_ML:8000"
   ```

2. **En la App Flutter:**
   ```dart
   const String baseUrl = "http://IP_DEL_GATEWAY:8001";
   ```

3. **Verificar conectividad:**
   ```bash
   # Desde el Gateway, probar:
   curl http://IP_DEL_SERVIDOR_ML:8000/health
   
   # Desde el celular, probar:
   http://IP_DEL_GATEWAY:8001/ping
   ```

---

## 🎯 Escenarios de Uso

### Desarrollo (todo en un PC)
```
localhost:8000 - Servidor ML
localhost:8001 - Gateway
Celular → 192.168.1.X:8001
```

### Producción (dispositivos separados)
```
PC-1 (192.168.1.10:8000) - Servidor ML
PC-2 (192.168.1.20:8001) - Gateway + ESP32
Celular → 192.168.1.20:8001
```

### Con Raspberry Pi
```
PC (192.168.1.10:8000) - Servidor ML
Raspberry Pi (192.168.1.30:8001) - Gateway + ESP32
Celular → 192.168.1.30:8001
```

---

## 📝 Notas Importantes

1. **Gateway independiente:** Puede estar en cualquier dispositivo con Python y Bluetooth
2. **Servidor ML:** Requiere recursos (CPU/GPU) para BLIP
3. **Documentación centralizada:** Todo en `docs/`
4. **Tests organizados:** Fácil ejecutar pruebas específicas
5. **Scripts reutilizables:** Los .bat funcionan desde cualquier ubicación

---

## 🔍 Archivos de Configuración

- `api/.venv311/` - Entorno virtual del servidor ML
- `gateway/venv/` - Entorno virtual del gateway (crear primero)
- `gateway/requirements.txt` - Dependencias del gateway
- `ejecutables/*.bat` - Scripts ajustados a nueva estructura

---

**Esta estructura permite:**
- ✅ Separación física de componentes
- ✅ Escalabilidad (múltiples gateways/servidores)
- ✅ Mantenimiento más fácil
- ✅ Testing independiente
- ✅ Documentación centralizada
- ✅ Despliegue flexible

**Última actualización:** 25/12/2025
