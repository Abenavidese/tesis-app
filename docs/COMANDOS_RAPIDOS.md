# ⚡ COMANDOS RÁPIDOS - Cheat Sheet

## 🚀 Inicio Rápido

### Iniciar todo el sistema
```bash
cd C:\Users\EleXc\Desktop\tesis_app\api
start_all.bat
```

### O iniciar por separado
```bash
# Terminal 1 - Servidor ML
start_ml_server.bat

# Terminal 2 - Gateway
start_gateway.bat
```

---

## 🧪 Testing

### Test completo del Gateway
```bash
python test_gateway.py
```

### Test solo ESP32
```bash
python test_esp32_serial.py
```

### Test manual ESP32
```bash
curl -X POST http://localhost:8001/test_esp32
```

---

## 🔵 Configuración ESP32

### Listar puertos COM disponibles
```bash
python test_esp32_serial.py
```

### Configurar ESP32 en Gateway
```bash
curl -X POST http://localhost:8001/configure_esp32 ^
  -H "Content-Type: application/json" ^
  -d "{\"enabled\": true, \"port\": \"COM5\", \"baudrate\": 115200}"
```

### Ver configuración actual
```bash
curl http://localhost:8001/health
```

---

## 📡 Endpoints del Sistema

### Health Checks
```bash
# Gateway
curl http://localhost:8001/health
curl http://localhost:8001/ping

# Servidor ML
curl http://localhost:8000/health
curl http://localhost:8000/ping
```

### Test Predict (con imagen)
```bash
curl -X POST http://localhost:8001/predict ^
  -F "image=@test_image.jpg"
```

### Test Evaluate (respuesta correcta)
```bash
curl -X POST http://localhost:8001/evaluate ^
  -H "Content-Type: application/json" ^
  -d "{\"texto_modelo\":\"un burro parado\",\"texto_nino\":\"es un burro\",\"umbral\":0.6}"
```

### Test Evaluate (respuesta incorrecta)
```bash
curl -X POST http://localhost:8001/evaluate ^
  -H "Content-Type: application/json" ^
  -d "{\"texto_modelo\":\"un burro parado\",\"texto_nino\":\"es un caballo\",\"umbral\":0.6}"
```

---

## 🔍 Diagnóstico

### Ver procesos Python corriendo
```powershell
Get-Process python
```

### Matar todos los procesos Python
```powershell
Stop-Process -Name python -Force
```

### Ver qué está usando el puerto 8000
```powershell
netstat -ano | findstr :8000
```

### Ver qué está usando el puerto 8001
```powershell
netstat -ano | findstr :8001
```

### Listar dispositivos Bluetooth
```powershell
Get-PnpDevice | Where-Object {$_.Class -eq "Bluetooth"}
```

### Listar puertos COM
```powershell
Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID
```

---

## 🐛 Solución Rápida de Problemas

### Puerto ocupado
```bash
# Ver qué proceso usa el puerto
netstat -ano | findstr :8001

# Matar proceso por PID
taskkill /PID <número> /F
```

### Reinstalar dependencias
```bash
cd C:\Users\EleXc\Desktop\tesis_app\api
.venv311\Scripts\activate
pip install -r requirements.txt
```

### Crear requirements.txt (si no existe)
```bash
pip freeze > requirements.txt
```

### Resetear gateway
```bash
# Ctrl+C para detener
# Volver a iniciar
python gateway.py
```

---

## 📱 Configuración Flutter

### Obtener IP del PC
```powershell
ipconfig
```
Buscar "Dirección IPv4" en tu adaptador Wi-Fi

### Verificar conexión desde celular
```bash
# Abrir en navegador del celular:
http://192.168.1.XXX:8001/ping
```

### URL que debe usar Flutter
```dart
const String baseUrl = "http://192.168.1.XXX:8001";
```

---

## 🔧 Mantenimiento

### Ver logs en tiempo real (si los rediriges)
```powershell
Get-Content -Wait gateway.log
```

### Limpiar archivos temporales
```bash
del __pycache__ /s /q
del *.pyc /s /q
```

### Backup de configuración
```bash
copy gateway.py gateway.py.backup
copy main.py main.py.backup
```

---

## 📊 Información del Sistema

### Ver versión Python
```bash
python --version
```

### Ver paquetes instalados
```bash
pip list
```

### Ver info del modelo BLIP
```bash
python -c "from blip.generation import get_global_generator; print(get_global_generator())"
```

### Ver espacio en disco
```powershell
Get-PSDrive C
```

---

## 🎯 Comandos de Producción

### Iniciar Gateway en background
```bash
start /B python gateway.py > gateway.log 2>&1
```

### Iniciar ML Server en background
```bash
start /B python -m uvicorn main:app --host 0.0.0.0 --port 8000 > ml_server.log 2>&1
```

### Ver logs
```bash
type gateway.log
type ml_server.log
```

---

## 💾 Respaldo y Restauración

### Backup del sistema
```bash
xcopy /E /I api api_backup
```

### Backup solo archivos importantes
```bash
copy *.py backup\
copy *.md backup\
copy *.bat backup\
```

### Restaurar desde backup
```bash
xcopy /E /Y api_backup api
```

---

## 🔐 Seguridad (Para producción)

### Generar clave secreta
```python
python -c "import secrets; print(secrets.token_hex(32))"
```

### Verificar firewall
```powershell
Get-NetFirewallRule | Where-Object {$_.LocalPort -eq 8001}
```

### Agregar regla de firewall
```powershell
New-NetFirewallRule -DisplayName "API Gateway" -Direction Inbound -LocalPort 8001 -Protocol TCP -Action Allow
```

---

## 📈 Monitoreo

### Ver uso de CPU de Python
```powershell
Get-Process python | Select-Object CPU, WorkingSet, ID
```

### Ver memoria usada
```powershell
Get-Process python | Measure-Object WorkingSet -Sum
```

### Ver tiempo de ejecución
```powershell
Get-Process python | Select-Object StartTime
```

---

## 🎨 Personalizaciones

### Cambiar puerto del Gateway
Editar `gateway.py`, última línea:
```python
uvicorn.run(app, host="0.0.0.0", port=8001)  # Cambiar 8001
```

### Cambiar puerto del ML Server
Editar `start_ml_server.bat`:
```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000  # Cambiar 8000
```

### Cambiar timeout de requests
Editar `gateway.py`:
```python
async with httpx.AsyncClient(timeout=30.0) as client:  # Cambiar 30.0
```

---

## 📚 Recursos Útiles

### Documentación
- [INICIO_RAPIDO.md](INICIO_RAPIDO.md) - Guía de inicio
- [ARQUITECTURA.md](ARQUITECTURA.md) - Arquitectura del sistema
- [ESP32_BLUETOOTH_SIMPLE.md](ESP32_BLUETOOTH_SIMPLE.md) - Configurar ESP32
- [README_GATEWAY.md](README_GATEWAY.md) - Documentación del Gateway

### URLs Importantes
- Gateway: http://localhost:8001
- Gateway Docs: http://localhost:8001/docs
- ML Server: http://localhost:8000
- ML Server Docs: http://localhost:8000/docs

---

## 💡 Tips Pro

### Alias útiles (PowerShell Profile)
```powershell
# Agregar a: $PROFILE
function Start-TesisApp {
    cd C:\Users\EleXc\Desktop\tesis_app\api
    .\start_all.bat
}

function Test-TesisApp {
    python C:\Users\EleXc\Desktop\tesis_app\api\test_gateway.py
}

Set-Alias tesis Start-TesisApp
Set-Alias test-tesis Test-TesisApp
```

### Entonces solo ejecutas:
```powershell
tesis        # Inicia todo
test-tesis   # Corre tests
```

---

**¡Guarda este archivo como referencia rápida!** 📌
