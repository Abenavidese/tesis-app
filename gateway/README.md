# 🌐 API Gateway - Instalación y Configuración

## 📋 Este es el Gateway que va en un dispositivo separado

Este Gateway puede estar en:
- Otro PC en la misma red
- Una Raspberry Pi
- Cualquier dispositivo con Python 3.11+

## 🔧 Instalación

### 1. Instalar Python 3.11+
Asegúrate de tener Python 3.11 o superior instalado.

### 2. Crear entorno virtual
```bash
cd gateway
python -m venv venv
```

### 3. Activar entorno virtual

**Windows:**
```bash
venv\Scripts\activate
```

**Linux/Mac:**
```bash
source venv/bin/activate
```

### 4. Instalar dependencias
```bash
pip install -r requirements.txt
```

## 🚀 Iniciar el Gateway

```bash
python gateway.py
```

El Gateway se iniciará en: **http://0.0.0.0:8001**

## ⚙️ Configuración

### Cambiar URL del Servidor ML

Editar `gateway.py`, línea ~20:
```python
MODEL_SERVER_URL = "http://192.168.1.XXX:8000"  # IP del servidor con el modelo
```

### Configurar ESP32

**Opción 1 - Por API:**
```bash
curl -X POST http://localhost:8001/configure_esp32 \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "port": "COM5", "baudrate": 115200}'
```

**Opción 2 - Editar gateway.py:**
```python
ESP32_ENABLED = True
ESP32_PORT = "COM5"  # Tu puerto COM
ESP32_BAUDRATE = 115200
```

## 📡 Endpoints

- `GET /` - Información del gateway
- `GET /health` - Estado del sistema
- `GET /ping` - Test de conectividad
- `POST /predict` - Generar caption (proxy al servidor ML)
- `POST /evaluate` - Evaluar respuesta + control ESP32
- `POST /configure_esp32` - Configurar ESP32
- `POST /test_esp32` - Probar conexión ESP32

## 🔍 Verificar Funcionamiento

```bash
curl http://localhost:8001/health
```

## 📝 Notas

- El Gateway necesita poder comunicarse con el servidor ML (puerto 8000)
- Asegúrate de que ambos dispositivos estén en la misma red
- Para ESP32, debe estar emparejado por Bluetooth en este dispositivo

## 🌍 Acceso desde la Red

Para que otros dispositivos (como el celular) puedan acceder:

1. Encuentra la IP del dispositivo donde corre el gateway:
   ```bash
   ipconfig  # Windows
   ifconfig  # Linux/Mac
   ```

2. El celular debe usar: `http://IP_DEL_GATEWAY:8001`

3. Verificar firewall no bloquee el puerto 8001

## 📚 Documentación Completa

Ver la carpeta `docs/` en el repositorio principal para documentación detallada.
