# 🚀 INICIO RÁPIDO - Sistema Completo

## ⚡ TL;DR (Inicio en 30 segundos)

```bash
# 1. Ir al directorio
cd C:\Users\EleXc\Desktop\tesis_app\api

# 2. Iniciar TODO el sistema (abre 2 ventanas)
start_all.bat
```

¡Listo! Tendrás:
- 🤖 Servidor ML en http://localhost:8000
- 🌐 API Gateway en http://localhost:8001

---

## 📋 Checklist de Inicio

### Antes de empezar (solo primera vez):

- [ ] Python 3.11 instalado
- [ ] Entorno virtual creado: `.venv311`
- [ ] Dependencias instaladas:
  ```bash
  pip install fastapi uvicorn pillow transformers torch sentence-transformers spacy httpx
  python -m spacy download es_core_news_sm
  ```
- [ ] Modelo BLIP descargado: `blip-final-5/`

### Para usar ESP32 (opcional):

- [ ] `pip install pyserial`
- [ ] ESP32 programado con código Bluetooth Serial
- [ ] ESP32 emparejado en Windows
- [ ] Puerto COM del ESP32 identificado (ej: COM5)

---

## 🎮 Opciones de Inicio

### Opción 1: TODO AUTOMÁTICO (Recomendado)

```bash
start_all.bat
```

Abre 2 ventanas:
1. **Servidor ML** (puerto 8000)
2. **API Gateway** (puerto 8001)

### Opción 2: MANUAL (para desarrollo)

**Terminal 1 - Servidor ML:**
```bash
start_ml_server.bat
```

**Terminal 2 - API Gateway:**
```bash
start_gateway.bat
```

### Opción 3: LÍNEA DE COMANDOS

**Terminal 1:**
```bash
cd C:\Users\EleXc\Desktop\tesis_app\api
.venv311\Scripts\activate
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Terminal 2:**
```bash
cd C:\Users\EleXc\Desktop\tesis_app\api
.venv311\Scripts\activate
python gateway.py
```

---

## 🧪 Verificar que Todo Funciona

### 1. Probar Servidor ML (8000)

```bash
curl http://localhost:8000/health
```

**Respuesta esperada:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "message": "Modelo BLIP listo para generar captions"
}
```

### 2. Probar Gateway (8001)

```bash
curl http://localhost:8001/ping
```

**Respuesta esperada:**
```json
{
  "message": "pong",
  "status": "gateway_running"
}
```

### 3. Test Completo (Suite Automática)

```bash
python test_gateway.py
```

Esto ejecuta todos los tests y muestra un resumen.

---

## 🔧 Configuración del Sistema

### Cambiar Puerto del Servidor ML

Editar `gateway.py`, línea ~20:
```python
MODEL_SERVER_URL = "http://localhost:8000"  # Cambiar puerto aquí
```

### Habilitar ESP32

**Método 1: API (mientras corre)**
```bash
curl -X POST http://localhost:8001/configure_esp32 ^
  -H "Content-Type: application/json" ^
  -d "{\"enabled\": true, \"port\": \"COM5\", \"baudrate\": 115200}"
```

⚠️ **Cambiar COM5 por tu puerto real**

**Método 2: Editar gateway.py** (líneas ~24-26)
```python
ESP32_ENABLED = True
ESP32_PORT = "COM5"  # Puerto COM del ESP32
ESP32_BAUDRATE = 115200
```

---

## 📱 Configurar Flutter App

### Cambiar URL en la App

Ubicación: `Aplication_Tesis/lib/core/services/api_service.dart`

```dart
// ANTES (directo al servidor ML)
const String baseUrl = "http://192.168.1.100:8000";

// AHORA (a través del Gateway)
const String baseUrl = "http://192.168.1.100:8001";
```

⚠️ **Importante:** Usa la IP de tu PC, no `localhost`

### Obtener IP de tu PC

**Windows:**
```bash
ipconfig
```
Buscar "Dirección IPv4" en tu adaptador de red Wi-Fi.

**Verificar desde el celular:**
```bash
# En el celular, abrir navegador:
http://TU_IP:8001/ping

# Debe mostrar: {"message":"pong","status":"gateway_running"}
```

---

## 🔍 URLs Útiles

### Servidor ML (8000)
- Health: http://localhost:8000/health
- Docs: http://localhost:8000/docs
- Ping: http://localhost:8000/ping

### API Gateway (8001)
- Health: http://localhost:8001/health
- Docs: http://localhost:8001/docs
- Ping: http://localhost:8001/ping

---

## 📊 Flujo Normal de Uso

1. **Iniciar servidores** (`start_all.bat`)
2. **Verificar health** checks
3. **Abrir app Flutter** en celular
4. **Tomar foto** → Caption generado
5. **Grabar voz** → Evaluación
6. **Si correcta** → ESP32 se activa (si está configurado)

---

## 🐛 Problemas Comunes

### "Address already in use"

**Puerto 8000 ocupado:**
```bash
# Encontrar proceso
netstat -ano | findstr :8000

# Matar proceso (reemplazar PID)
taskkill /PID <número> /F
```

**Puerto 8001 ocupado:** (mismo proceso con 8001)

### "Connection refused"

1. Verificar que ambos servidores estén corriendo
2. Verificar firewall de Windows
3. Verificar que estás en la misma red (celular y PC)

### "Model not found"

```bash
# Verificar que el modelo existe
dir blip-final-5\model.safetensors
```

Si no existe, re-descargar el modelo.

### ESP32 no responde

1. Ver [ESP32_SETUP.md](ESP32_SETUP.md)
2. Verificar que `bleak` esté instalado
3. Probar: `curl -X POST http://localhost:8001/test_esp32`

---

## 🛑 Detener el Sistema

### Si usaste `start_all.bat`:
- Cerrar las 2 ventanas que se abrieron
- O presionar `Ctrl+C` en cada ventana

### Forzar detención:
```bash
# Matar todos los procesos Python
taskkill /IM python.exe /F
```

⚠️ Esto mata TODOS los procesos Python, úsalo con cuidado.

---

## 📝 Logs y Debugging

### Ver logs en tiempo real

**Servidor ML:**
- La ventana muestra logs automáticamente
- Busca ✅ para operaciones exitosas
- Busca ❌ para errores

**API Gateway:**
- Similar, muestra cada petición
- Muestra cuándo se envían señales al ESP32

### Logs detallados

Para más detalle, ejecutar manualmente:
```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --log-level debug
```

---

## 🎯 Siguiente Paso: Testing

Una vez todo corriendo, ejecuta:

```bash
python test_gateway.py
```

Esto probará:
- ✅ Conectividad
- ✅ Health checks
- ✅ Generación de captions
- ✅ Evaluación de respuestas

---

## 📚 Más Información

- **Arquitectura completa:** [ARQUITECTURA.md](ARQUITECTURA.md)
- **Configurar ESP32:** [ESP32_SETUP.md](ESP32_SETUP.md)
- **Documentación Gateway:** [README_GATEWAY.md](README_GATEWAY.md)

---

## 💡 Tips

1. **Desarrollo:** Usa `--reload` en uvicorn para auto-recargar cambios
2. **Producción:** Quita `--reload` para mejor rendimiento
3. **Testing:** Usa `test_gateway.py` antes de probar con la app
4. **ESP32:** Configura y prueba por separado antes de integrar
5. **Firewall:** Si el celular no conecta, revisa el firewall de Windows

---

## ✅ Sistema Listo

Si todos los health checks pasan:
- ✅ Servidor ML corriendo
- ✅ API Gateway corriendo
- ✅ Comunicación entre ellos funciona
- ✅ (Opcional) ESP32 configurado

**¡Estás listo para usar la app!** 🎉

---

**Última actualización:** 25/12/2025
**Versión:** 1.0.0
