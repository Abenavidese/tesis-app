# 🔵 Configuración ESP32 - Guía Completa

## 📋 Requisitos

### Hardware:
- ESP32 con Bluetooth
- Cable USB para programación
- LED o componente para activar con señal

### Software:
- Arduino IDE instalado
- Biblioteca ESP32 instalada en Arduino IDE
- Python con `bleak` instalado: `pip install bleak`

## 🔧 Paso 1: Programar el ESP32

### Código Arduino (ESP32_Bluetooth_Receiver.ino):

```cpp
/*
 * ESP32 Bluetooth Receiver para Tesis App
 * Recibe señales del API Gateway cuando la respuesta es correcta
 */

#include "BluetoothSerial.h"

// Verificar que Bluetooth está habilitado
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth no está habilitado! Ejecuta `make menuconfig` para habilitarlo
#endif

BluetoothSerial SerialBT;

// Pines
const int LED_PIN = 2;  // LED integrado del ESP32
const int BUZZER_PIN = 4;  // Opcional: buzzer para sonido

// Variables
unsigned long lastSignalTime = 0;
int correctAnswersCount = 0;

void setup() {
  // Inicializar Serial para debug
  Serial.begin(115200);
  
  // Configurar pines
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);
  
  // Inicializar Bluetooth
  SerialBT.begin("ESP32_TesisApp"); // Nombre del dispositivo Bluetooth
  Serial.println("🔵 Bluetooth iniciado - Esperando conexión...");
  Serial.println("📱 Nombre del dispositivo: ESP32_TesisApp");
}

void loop() {
  // Verificar si hay datos disponibles por Bluetooth
  if (SerialBT.available()) {
    char received = SerialBT.read();
    Serial.print("📩 Señal recibida: ");
    Serial.println(received);
    
    // Procesar señales
    switch(received) {
      case 'b':  // Respuesta correcta (b = "bueno")
        handleCorrectAnswer();
        break;
        
      case 't':  // Señal de prueba (t = "test")
        handleTestSignal();
        break;
        
      case 'r':  // Reset contador (r = "reset")
        resetCounter();
        break;
        
      default:
        Serial.println("⚠️ Señal desconocida");
        break;
    }
  }
  
  // Pequeña pausa para no saturar el loop
  delay(10);
}

/**
 * Maneja la señal de respuesta correcta
 */
void handleCorrectAnswer() {
  correctAnswersCount++;
  lastSignalTime = millis();
  
  Serial.println("✅ ¡RESPUESTA CORRECTA!");
  Serial.print("📊 Total respuestas correctas: ");
  Serial.println(correctAnswersCount);
  
  // Patrón de celebración con LED
  for(int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    tone(BUZZER_PIN, 1000);  // Tono agudo
    delay(200);
    
    digitalWrite(LED_PIN, LOW);
    noTone(BUZZER_PIN);
    delay(200);
  }
  
  // Enviar confirmación de vuelta
  SerialBT.println("OK");
}

/**
 * Maneja la señal de prueba
 */
void handleTestSignal() {
  Serial.println("🧪 Señal de prueba recibida");
  
  // Parpadeo simple para confirmar conexión
  digitalWrite(LED_PIN, HIGH);
  tone(BUZZER_PIN, 500);  // Tono medio
  delay(500);
  
  digitalWrite(LED_PIN, LOW);
  noTone(BUZZER_PIN);
  
  // Enviar confirmación
  SerialBT.println("TEST_OK");
}

/**
 * Resetea el contador de respuestas correctas
 */
void resetCounter() {
  correctAnswersCount = 0;
  Serial.println("🔄 Contador reseteado");
  
  // Confirmación visual
  for(int i = 0; i < 2; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
  
  SerialBT.println("RESET_OK");
}
```

### 📤 Subir código al ESP32:

1. Abrir Arduino IDE
2. Seleccionar: `Herramientas > Placa > ESP32 Dev Module`
3. Conectar ESP32 por USB
4. Seleccionar el puerto COM correcto
5. Click en "Subir" ⬆️

## 🔍 Paso 2: Encontrar la Dirección MAC del ESP32

### Opción A: Código Arduino para obtener MAC

```cpp
// Programa simple para obtener la MAC del ESP32
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_TesisApp");
  
  Serial.println("\n=== INFORMACIÓN ESP32 ===");
  Serial.print("📍 Dirección MAC Bluetooth: ");
  Serial.println(SerialBT.getBtAddressString());
}

void loop() {
  delay(1000);
}
```

### Opción B: Desde Windows (Python)

```python
# scan_bluetooth.py
import asyncio
from bleak import BleakScanner

async def scan_devices():
    print("🔍 Buscando dispositivos Bluetooth...")
    devices = await BleakScanner.discover()
    
    print(f"\n📱 Dispositivos encontrados: {len(devices)}\n")
    for device in devices:
        print(f"Nombre: {device.name}")
        print(f"Dirección: {device.address}")
        print(f"RSSI: {device.rssi}")
        print("-" * 50)

asyncio.run(scan_devices())
```

Ejecutar:
```bash
python scan_bluetooth.py
```

Buscar un dispositivo llamado "ESP32_TesisApp" y anotar su dirección (XX:XX:XX:XX:XX:XX).

## ⚙️ Paso 3: Configurar el Gateway

### Método 1: Via API

```bash
curl -X POST http://localhost:8001/configure_esp32 ^
  -H "Content-Type: application/json" ^
  -d "{\"enabled\": true, \"address\": \"XX:XX:XX:XX:XX:XX\"}"
```

### Método 2: Editar gateway.py

Modificar estas líneas en `gateway.py`:

```python
# Configuración Bluetooth para ESP32
ESP32_ENABLED = True  # Cambiar a True
ESP32_ADDRESS = "XX:XX:XX:XX:XX:XX"  # Tu dirección MAC
```

## 🧪 Paso 4: Probar la Conexión

### 1. Asegurar que el ESP32 está encendido y visible

### 2. Probar conexión desde el Gateway:

```bash
curl -X POST http://localhost:8001/test_esp32
```

**Resultado esperado:**
- El LED del ESP32 debe parpadear
- El buzzer debe sonar (si está conectado)
- Console del ESP32 (Serial Monitor) debe mostrar: "🧪 Señal de prueba recibida"

### 3. Probar con evaluación real:

```python
import requests

response = requests.post("http://localhost:8001/evaluate", json={
    "texto_modelo": "un burro parado en un campo",
    "texto_nino": "es un burro",
    "umbral": 0.6
})

print(response.json())
# Si es correcta, el ESP32 debe activarse automáticamente
```

## 🎯 Señales del ESP32

| Señal | Significado | Acción |
|-------|-------------|--------|
| `b` | Respuesta correcta | 3 parpadeos LED + 3 tonos |
| `t` | Test de conexión | 1 parpadeo LED + 1 tono |
| `r` | Reset contador | 2 parpadeos rápidos |

## 📊 Monitorear el ESP32

Para ver los logs en tiempo real:

1. Abrir Arduino IDE
2. `Herramientas > Monitor Serie`
3. Seleccionar `115200 baud`

Verás mensajes como:
```
🔵 Bluetooth iniciado - Esperando conexión...
📱 Nombre del dispositivo: ESP32_TesisApp
📩 Señal recibida: b
✅ ¡RESPUESTA CORRECTA!
📊 Total respuestas correctas: 1
```

## 🐛 Troubleshooting

### ESP32 no aparece en el escaneo
1. Asegurar que el código está subido correctamente
2. Resetear el ESP32
3. Verificar que Bluetooth del ESP32 está habilitado
4. Acercarse más al ESP32

### Gateway no puede conectar
1. Verificar dirección MAC correcta
2. Asegurar que `bleak` está instalado: `pip install bleak`
3. En Windows, puede requerir ejecutar como Administrador
4. Verificar que no hay otro dispositivo conectado al ESP32

### LED no se enciende
1. Verificar pin correcto (GPIO 2 para LED integrado)
2. Probar con LED externo en otro pin
3. Verificar conexión Serial para ver si la señal llega

### Buzzer no suena
1. Verificar conexiones del buzzer
2. Buzzer debe estar en GPIO 4 (o cambiar PIN en código)
3. Algunos buzzers requieren GND también

## 🔄 Actualizar el Circuito

### Conexiones Recomendadas:

```
ESP32          Componente
------         ----------
GPIO 2    ---> LED Integrado (ya incluido)
GPIO 4    ---> Buzzer (+)
GND       ---> Buzzer (-)
GPIO 5    ---> LED Externo (+) [Opcional]
```

### Agregar más componentes:

```cpp
const int MOTOR_PIN = 5;
const int LED_VERDE_PIN = 18;
const int LED_ROJO_PIN = 19;

void setup() {
  pinMode(MOTOR_PIN, OUTPUT);
  pinMode(LED_VERDE_PIN, OUTPUT);
  pinMode(LED_ROJO_PIN, OUTPUT);
}

void handleCorrectAnswer() {
  // LED verde
  digitalWrite(LED_VERDE_PIN, HIGH);
  
  // Motor por 2 segundos
  digitalWrite(MOTOR_PIN, HIGH);
  delay(2000);
  digitalWrite(MOTOR_PIN, LOW);
  
  digitalWrite(LED_VERDE_PIN, LOW);
}
```

## 📝 Notas Importantes

1. **Rango Bluetooth:** Mantener ESP32 a menos de 10 metros del PC
2. **Alimentación:** ESP32 puede alimentarse por USB o batería
3. **Interferencias:** Evitar muchos dispositivos Bluetooth cerca
4. **Seguridad:** En producción, considera autenticación Bluetooth

## 🎉 Listo!

Una vez configurado, el flujo completo será:

1. 📱 Niño habla → Flutter captura audio
2. 🎤 Flutter convierte audio a texto (speech-to-text en el celular)
3. 📸 Flutter toma foto → Gateway → ML Server
4. 🤖 BLIP genera caption → Gateway → Flutter
5. 🧠 Flutter compara textos → Gateway evalúa
6. ✅ Si es correcto → Gateway → 🔵 ESP32 (LED + Buzzer)
7. 🎊 Niño ve animación en app Y retroalimentación física del ESP32

¡Experiencia de aprendizaje completa! 🌟
