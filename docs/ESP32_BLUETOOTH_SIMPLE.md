# 🔵 ESP32 Bluetooth Serial - Guía Simple

## 📋 Resumen

El ESP32 ya está configurado para recibir caracteres por Bluetooth Serial. Solo necesitas:
1. Emparejar el ESP32 con tu PC
2. Encontrar el puerto COM asignado
3. Configurar el gateway
4. ¡Listo!

---

## 🔧 Paso 1: Código Arduino (Ya lo tiene tu compañero)

```cpp
// El ESP32 solo necesita recibir por Serial Bluetooth
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_TesisApp"); // Nombre Bluetooth
  pinMode(2, OUTPUT); // LED
  Serial.println("Bluetooth listo!");
}

void loop() {
  if (SerialBT.available()) {
    char c = SerialBT.read();
    
    if (c == 'b') {
      // ¡Respuesta correcta!
      digitalWrite(2, HIGH);
      Serial.println("✅ Respuesta correcta!");
      delay(1000);
      digitalWrite(2, LOW);
    }
  }
}
```

---

## 💻 Paso 2: Emparejar ESP32 en Windows

### 1. Encender el ESP32
El código Bluetooth debe estar cargado y corriendo.

### 2. Abrir Configuración de Bluetooth en Windows

**Windows 11:**
- `Inicio` → `Configuración` → `Bluetooth y dispositivos`

**Windows 10:**
- `Inicio` → `Configuración` → `Dispositivos` → `Bluetooth`

### 3. Agregar dispositivo
1. Click en **"Agregar dispositivo"** o **"Agregar Bluetooth u otro dispositivo"**
2. Seleccionar **"Bluetooth"**
3. Esperar a que aparezca **"ESP32_TesisApp"** (o el nombre configurado)
4. Click en el dispositivo
5. Si pide PIN, probar: `1234` o `0000`
6. Esperar a que diga **"Conectado"**

---

## 🔍 Paso 3: Encontrar el Puerto COM

### Método 1: Administrador de Dispositivos

1. Presiona `Win + X` → **"Administrador de dispositivos"**
2. Expandir **"Puertos (COM y LPT)"**
3. Buscar algo como:
   - `Standard Serial over Bluetooth link (COM5)`
   - `ESP32 Bluetooth (COM7)`
   - O cualquier puerto COM nuevo
4. **Anotar el número del puerto** (ej: COM5, COM7, etc.)

### Método 2: PowerShell

```powershell
Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID
```

Buscar el puerto relacionado con Bluetooth o ESP32.

### Método 3: Python Script

```python
# list_ports.py
import serial.tools.list_ports

ports = serial.tools.list_ports.comports()
for port in ports:
    print(f"{port.device} - {port.description}")
```

Ejecutar:
```bash
python list_ports.py
```

---

## ⚙️ Paso 4: Configurar el Gateway

### Opción A: Por API (Recomendado)

```bash
curl -X POST http://localhost:8001/configure_esp32 ^
  -H "Content-Type: application/json" ^
  -d "{\"enabled\": true, \"port\": \"COM5\", \"baudrate\": 115200}"
```

⚠️ **Cambiar COM5 por tu puerto real**

### Opción B: Editar gateway.py

Modificar las líneas en [gateway.py](c:\Users\EleXc\Desktop\tesis_app\api\gateway.py):

```python
# Configuración Bluetooth para ESP32
ESP32_ENABLED = True
ESP32_PORT = "COM5"  # ⚠️ CAMBIAR por tu puerto
ESP32_BAUDRATE = 115200
```

---

## 🧪 Paso 5: Probar la Conexión

### 1. Asegurar que el gateway está corriendo

```bash
python gateway.py
```

### 2. Probar desde el endpoint

```bash
curl -X POST http://localhost:8001/test_esp32
```

**Resultado esperado:**
- ✅ Console del gateway: "Mensaje enviado al ESP32: t"
- ✅ LED del ESP32 se enciende brevemente
- ✅ Serial Monitor del ESP32: "🧪 Señal de prueba recibida"

### 3. Probar con evaluación real

```bash
curl -X POST http://localhost:8001/evaluate ^
  -H "Content-Type: application/json" ^
  -d "{\"texto_modelo\":\"un burro\",\"texto_nino\":\"es un burro\",\"umbral\":0.6}"
```

Si la respuesta es correcta, el ESP32 debe recibir 'b' y activarse.

---

## 🐛 Troubleshooting

### "Puerto COM no encontrado"

1. **Verificar emparejamiento:**
   - Ir a configuración Bluetooth
   - El ESP32 debe estar en la lista de dispositivos emparejados
   - Debe decir "Conectado"

2. **Reconectar Bluetooth:**
   - Desconectar el ESP32 en Windows
   - Volver a conectar
   - Verificar nuevo puerto COM

3. **Reiniciar ESP32:**
   - Desconectar alimentación
   - Volver a conectar
   - Verificar que el Bluetooth se inicia

### "Access Denied" o "Puerto ocupado"

1. **Cerrar Serial Monitor de Arduino IDE**
   - No puedes tener 2 programas usando el mismo puerto

2. **Verificar permisos:**
   - Ejecutar PowerShell/CMD como Administrador

3. **Reiniciar gateway:**
   ```bash
   # Detener gateway (Ctrl+C)
   # Volver a iniciar
   python gateway.py
   ```

### "pyserial not found"

```bash
pip install pyserial
```

### ESP32 no responde

1. **Verificar código Arduino:**
   - Asegurar que `SerialBT.begin("ESP32_TesisApp")` está en setup()
   - Verificar que está leyendo `SerialBT.available()`

2. **Verificar baudrate:**
   - Por defecto: 115200
   - Debe coincidir entre Arduino y gateway.py

3. **Monitor Serial:**
   - Abrir Serial Monitor en Arduino IDE
   - Verificar que muestra "Bluetooth listo!"
   - Ver si llegan mensajes cuando envías desde el gateway

---

## 📊 Flujo de Comunicación

```
Gateway (Python)
    ↓
Serial/Bluetooth (Puerto COM5)
    ↓
ESP32 Bluetooth Serial
    ↓
SerialBT.read() en Arduino
    ↓
Procesa caracter recibido
```

---

## 💡 Comandos Útiles

### Listar puertos COM disponibles:
```bash
mode
```

### Ver dispositivos Bluetooth emparejados:
```powershell
Get-PnpDevice | Where-Object {$_.Class -eq "Bluetooth"}
```

### Instalar PySerial:
```bash
pip install pyserial
```

### Test rápido de Serial (Python):
```python
import serial
ser = serial.Serial('COM5', 115200, timeout=1)
ser.write(b'b')
ser.close()
print("Enviado!")
```

---

## ✅ Checklist de Configuración

- [ ] ESP32 programado con código Bluetooth Serial
- [ ] ESP32 encendido y corriendo
- [ ] ESP32 emparejado en Windows
- [ ] Puerto COM identificado (ej: COM5)
- [ ] PySerial instalado: `pip install pyserial`
- [ ] Gateway configurado con puerto correcto
- [ ] Gateway corriendo: `python gateway.py`
- [ ] Test realizado: `curl -X POST http://localhost:8001/test_esp32`
- [ ] ESP32 responde correctamente

---

## 🎯 Ejemplo de Respuesta Correcta

Cuando un niño responde correctamente:

1. **Flutter App** → `POST /evaluate` → **Gateway**
2. **Gateway** → `POST /evaluate` → **ML Server**
3. **ML Server** → evalúa → `es_correcta: true`
4. **ML Server** → Gateway
5. **Gateway** → envía `'b'` por Serial → **ESP32**
6. **ESP32** → recibe `'b'` → activa LED/Buzzer
7. **Gateway** → respuesta al → **Flutter App**
8. **Flutter App** → muestra celebración

Todo en ~2 segundos! 🎉

---

## 📝 Notas Importantes

1. **Un solo programa a la vez:** No puedes tener Serial Monitor de Arduino Y el Gateway abiertos simultáneamente en el mismo puerto COM.

2. **Desconexión:** Si el ESP32 se desconecta, Windows puede asignarle otro puerto COM al reconectar.

3. **Rango:** Bluetooth clásico tiene buen rango (~10 metros), pero evita obstáculos.

4. **Latencia:** La comunicación Serial es casi instantánea (<100ms).

5. **Buffering:** El ESP32 tiene un buffer, pero con mensajes de 1 byte no hay problema.

---

**¡Mucho más simple que BLE! Solo necesitas el puerto COM y listo.** 🚀
