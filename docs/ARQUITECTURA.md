# 🏗️ ARQUITECTURA DEL SISTEMA - Vista Completa

```
╔══════════════════════════════════════════════════════════════════════════╗
║                         FLUJO COMPLETO DEL SISTEMA                        ║
╚══════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────┐
│  FASE 1: CAPTURA Y GENERACIÓN DE CAPTION                                │
└─────────────────────────────────────────────────────────────────────────┘

    📱 CELULAR (Flutter)
         │
         │ 1. Usuario toma foto
         │
         ▼
    [Imagen capturada]
         │
         │ 2. POST /predict
         │    Content-Type: multipart/form-data
         │    File: imagen.jpg
         │
         ▼
    🌐 API GATEWAY (Port 8001)
         │
         │ 3. Proxy request
         │    Forward image →
         │
         ▼
    🤖 SERVIDOR ML (Port 8000)
         │
         │ 4. BLIP Model procesa
         │    - Carga imagen
         │    - Genera caption
         │    - ~0.8-1.5 segundos
         │
         ▼
    [Caption: "a donkey standing in a field"]
         │
         │ 5. Response ←
         │
         ▼
    🌐 API GATEWAY
         │
         │ 6. Forward response ←
         │
         ▼
    📱 CELULAR
         │
         └──→ 📺 Muestra caption al usuario


┌─────────────────────────────────────────────────────────────────────────┐
│  FASE 2: CAPTURA DE VOZ Y EVALUACIÓN                                    │
└─────────────────────────────────────────────────────────────────────────┘

    📱 CELULAR (Flutter)
         │
         │ 7. Usuario graba respuesta vocal
         │    (usando speech_to_text plugin)
         │
         ▼
    [Audio capturado]
         │
         │ 8. Speech-to-Text (EN EL CELULAR)
         │    Plugin: speech_to_text
         │    Resultado: "es un burro"
         │
         ▼
    [Texto del niño: "es un burro"]
         │
         │ 9. POST /evaluate
         │    Content-Type: application/json
         │    Body: {
         │      "texto_modelo": "a donkey standing in a field",
         │      "texto_nino": "es un burro",
         │      "umbral": 0.6
         │    }
         │
         ▼
    🌐 API GATEWAY (Port 8001)
         │
         │ 10. Proxy request
         │     Forward JSON →
         │
         ▼
    🤖 SERVIDOR ML (Port 8000)
         │
         │ 11. Evaluador procesa
         │     - Extrae sujetos (SpaCy)
         │     - Compara sujetos
         │     - Calcula similitud semántica
         │     - Determina si es correcta
         │     - ~0.3-0.5 segundos
         │
         ▼
    [Resultado: es_correcta = True/False]
         │
         │ 12. Response ←
         │
         ▼
    🌐 API GATEWAY
         │
         ├──→ 13A. Si es_correcta == True
         │         │
         │         └──→ 🔵 ESP32 (Bluetooth)
         │                   │
         │                   └──→ Señal 'b' enviada
         │                         - LED parpadea 3 veces
         │                         - Buzzer suena 3 veces
         │                         - Contador incrementa
         │
         │ 14. Forward response ←
         │
         ▼
    📱 CELULAR
         │
         └──→ 📺 Muestra resultado al usuario
                 - ✅ "¡Felicidades, respuesta correcta!"
                 - ❌ "¡Inténtalo de nuevo!"


╔══════════════════════════════════════════════════════════════════════════╗
║                        COMPONENTES DEL SISTEMA                            ║
╚══════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────┐
│  📱 CELULAR (Flutter App)                                                │
│  ────────────────────────────────────────────────────────────────────   │
│  Responsabilidades:                                                      │
│  • Captura de foto (camera plugin)                                      │
│  • Captura de audio (microphone)                                        │
│  • Conversión audio → texto (speech_to_text plugin LOCAL)               │
│  • UI/UX para el niño                                                   │
│  • HTTP requests al Gateway                                             │
│  • Mostrar resultados y animaciones                                     │
│                                                                          │
│  Tecnologías:                                                           │
│  • Flutter/Dart                                                         │
│  • camera: ^0.10.0                                                      │
│  • speech_to_text: ^6.1.0 (procesa EN EL CELULAR)                      │
│  • http: ^1.0.0                                                         │
└─────────────────────────────────────────────────────────────────────────┘

                              ↕️ HTTP (Port 8001)

┌─────────────────────────────────────────────────────────────────────────┐
│  🌐 API GATEWAY (gateway.py)                                             │
│  ────────────────────────────────────────────────────────────────────   │
│  Responsabilidades:                                                      │
│  • Recibir peticiones del celular                                       │
│  • Rutear a servidor ML (proxy)                                         │
│  • Controlar ESP32 vía Bluetooth                                        │
│  • Decidir cuándo activar ESP32 (solo si respuesta correcta)           │
│  • Logging y monitoreo                                                  │
│                                                                          │
│  Tecnologías:                                                           │
│  • FastAPI                                                              │
│  • httpx (cliente HTTP async)                                           │
│  • bleak (Bluetooth Low Energy)                                         │
│  • Python 3.11                                                          │
│                                                                          │
│  Puerto: 8001                                                           │
│  Endpoints:                                                             │
│  • POST /predict → proxy a ML Server                                    │
│  • POST /evaluate → proxy a ML Server + control ESP32                   │
│  • GET /health → estado del sistema                                     │
│  • POST /configure_esp32 → configurar Bluetooth                         │
│  • POST /test_esp32 → probar conexión ESP32                             │
└─────────────────────────────────────────────────────────────────────────┘

                              ↕️ HTTP (Port 8000)
                              ↕️ Bluetooth BLE

            ┌─────────────────────┴───────────────────────┐
            │                                             │
            ▼                                             ▼

┌─────────────────────────────┐    ┌──────────────────────────────────────┐
│  🤖 SERVIDOR ML (main.py)   │    │  🔵 ESP32 (Bluetooth Device)         │
│  ──────────────────────────  │    │  ───────────────────────────────────  │
│  Responsabilidades:         │    │  Responsabilidades:                  │
│  • Cargar modelo BLIP       │    │  • Recibir señales Bluetooth         │
│  • Generar captions         │    │  • Activar LED/Buzzer                │
│  • Evaluar respuestas       │    │  • Contar respuestas correctas       │
│  • Procesamiento ML puro    │    │  • Feedback físico para el niño      │
│                             │    │                                      │
│  Tecnologías:               │    │  Tecnologías:                        │
│  • FastAPI                  │    │  • Arduino/ESP32                     │
│  • Transformers 4.53.2      │    │  • BluetoothSerial library           │
│  • PyTorch                  │    │  • GPIO control                      │
│  • Sentence-Transformers    │    │                                      │
│  • SpaCy (es_core_news_sm)  │    │  Componentes:                        │
│  • Python 3.11              │    │  • LED (GPIO 2)                      │
│                             │    │  • Buzzer (GPIO 4)                   │
│  Puerto: 8000               │    │  • Optional: Motor, más LEDs         │
│  Endpoints:                 │    │                                      │
│  • POST /predict            │    │  Señales:                            │
│  • POST /evaluate           │    │  • 'b' = respuesta correcta          │
│  • GET /health              │    │  • 't' = test                        │
│  • GET /ping                │    │  • 'r' = reset                       │
└─────────────────────────────┘    └──────────────────────────────────────┘


╔══════════════════════════════════════════════════════════════════════════╗
║                          FLUJO DE DATOS DETALLADO                         ║
╚══════════════════════════════════════════════════════════════════════════╝

CASO 1: RESPUESTA CORRECTA
──────────────────────────

Celular:      POST /evaluate {texto_modelo, texto_nino}
                    ↓
Gateway:      [Recibe petición]
                    ↓
              [Proxy a ML Server]
                    ↓
ML Server:    [Evalúa con evaluador.py]
              • Extrae sujeto_modelo = "burro"
              • Extrae sujeto_nino = "burro"
              • sujeto_igual = True ✅
              • Calcula similitud = 0.78
              • 0.78 >= 0.6 (umbral) → es_correcta = True
                    ↓
              [Retorna resultado al Gateway]
                    ↓
Gateway:      [Recibe es_correcta = True]
                    ↓
              [Envía señal 'b' al ESP32 via Bluetooth]
                    ↓
ESP32:        [Recibe 'b']
              • LED parpadea 3 veces 💡
              • Buzzer suena 3 veces 🔊
              • Incrementa contador
                    ↓
Gateway:      [Añade 'esp32_signal_sent: true' a respuesta]
                    ↓
              [Retorna al celular]
                    ↓
Celular:      [Muestra "¡Felicidades, respuesta correcta!" ✅]
              [Animación de celebración 🎉]


CASO 2: RESPUESTA INCORRECTA
─────────────────────────────

Celular:      POST /evaluate {texto_modelo, texto_nino}
                    ↓
Gateway:      [Recibe petición]
                    ↓
              [Proxy a ML Server]
                    ↓
ML Server:    [Evalúa con evaluador.py]
              • Extrae sujeto_modelo = "burro"
              • Extrae sujeto_nino = "caballo"
              • sujeto_igual = False ❌
              • similitud = 0.0
              • es_correcta = False
                    ↓
              [Retorna resultado al Gateway]
                    ↓
Gateway:      [Recibe es_correcta = False]
                    ↓
              [NO envía señal al ESP32]
                    ↓
              [Retorna al celular]
                    ↓
Celular:      [Muestra "¡Inténtalo de nuevo!" ❌]
              [Permite intentar otra vez]


╔══════════════════════════════════════════════════════════════════════════╗
║                           COMPARACIÓN: ANTES vs AHORA                     ║
╚══════════════════════════════════════════════════════════════════════════╝

ANTES (Arquitectura Monolítica):
────────────────────────────────

    Celular
       ↕️ (directo a main.py:8000)
    Servidor ML
    • /predict
    • /speech-to-text (Vosk) ← ELIMINADO
    • /evaluate

    Problemas:
    ✗ Todo en un solo servidor
    ✗ Procesamiento de audio en servidor (Vosk pesado)
    ✗ Sin control de hardware externo
    ✗ Difícil escalar
    ✗ Latencia alta por Vosk


AHORA (Arquitectura con Gateway):
──────────────────────────────────

    Celular (speech-to-text LOCAL)
       ↕️
    Gateway (8001)
       ↕️                    ↕️
    Servidor ML (8000)    ESP32 (Bluetooth)
    • /predict
    • /evaluate

    Ventajas:
    ✅ Separación de responsabilidades
    ✅ Speech-to-text en el celular (más rápido)
    ✅ Gateway maneja lógica de negocio
    ✅ Control de hardware (ESP32)
    ✅ Fácil escalar (múltiples ML servers)
    ✅ Latencia reducida
    ✅ Código más limpio y mantenible


╔══════════════════════════════════════════════════════════════════════════╗
║                             MÉTRICAS ESPERADAS                            ║
╚══════════════════════════════════════════════════════════════════════════╝

Operación                    Tiempo      Detalle
──────────────────────────   ─────────   ───────────────────────────────
POST /predict (imagen)       0.8-1.5s    BLIP procesa imagen
POST /evaluate (textos)      0.3-0.5s    Evaluador compara
Bluetooth → ESP32            0.1-0.2s    Envío de señal
Speech-to-text (celular)     1-3s        Plugin local del celular

FLUJO COMPLETO (respuesta correcta):
• Tomar foto: 0s (instantáneo)
• /predict: ~1.2s
• Hablar: 2-5s (usuario)
• Speech-to-text: ~2s
• /evaluate: ~0.4s
• ESP32 activación: ~0.15s
• TOTAL: ~6-9 segundos (incluyendo usuario)


╔══════════════════════════════════════════════════════════════════════════╗
║                       ARCHIVOS CREADOS/MODIFICADOS                        ║
╚══════════════════════════════════════════════════════════════════════════╝

NUEVOS:
✅ gateway.py                  - API Gateway principal
✅ README_GATEWAY.md           - Documentación del Gateway
✅ ESP32_SETUP.md              - Guía completa ESP32
✅ test_gateway.py             - Suite de tests
✅ start_ml_server.bat         - Script para iniciar ML Server
✅ start_gateway.bat           - Script para iniciar Gateway
✅ start_all.bat               - Script para iniciar todo
✅ ARQUITECTURA.md (este)      - Documentación arquitectura

MODIFICADOS:
🔧 main.py                     - Eliminado Vosk, solo ML
   • Removido /speech-to-text
   • Removido proceso_audio_with_vosk()
   • Removido get_vosk_model()
   • Removidos imports: wave, tempfile, json, os


╔══════════════════════════════════════════════════════════════════════════╗
║                          PRÓXIMOS PASOS                                   ║
╚══════════════════════════════════════════════════════════════════════════╝

1. ✅ Arquitectura Gateway creada
2. ✅ Vosk eliminado de main.py
3. ✅ Scripts de inicio creados
4. ✅ Documentación completa

5. 🔄 PENDIENTE: Programar ESP32 (ver ESP32_SETUP.md)
6. 🔄 PENDIENTE: Actualizar Flutter app:
      • Cambiar URL base a Gateway (port 8001)
      • Implementar speech_to_text LOCAL
      • Eliminar llamadas a /speech-to-text del servidor
7. 🔄 PENDIENTE: Testing completo del flujo
8. 🔄 PENDIENTE: Configurar ESP32 Bluetooth en Gateway
9. 🔄 PENDIENTE: Ajustar umbrales de evaluación si necesario

¡Sistema listo para testing! 🚀
```
