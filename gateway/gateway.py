# gateway.py - API Gateway para manejar peticiones del celular y comunicación con ESP32
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import asyncio
import serial
import threading
import time
from typing import Optional

app = FastAPI(
    title="API Gateway - Tesis App",
    description="Gateway para rutear peticiones entre celular, servidor ML y ESP32",
    version="1.0.0"
)

# Configurar CORS para aceptar peticiones del celular
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# CONFIGURACIÓN
# ============================================

# URL del servidor con el modelo BLIP
MODEL_SERVER_URL = "http://localhost:8000"

# Configuración Bluetooth para ESP32
ESP32_ENABLED = True  # Cambia a False si no quieres usar ESP32
ESP32_PORT = "COM3"  # Puerto COM del ESP32 (ej: "COM5" en Windows)
ESP32_BAUDRATE = 115200  # Velocidad de comunicación serial

# Variables globales para la conexión serial persistente
esp32_serial = None
esp32_thread = None
esp32_connected = False

print("🚀 API Gateway iniciado")
print(f"📡 Servidor ML: {MODEL_SERVER_URL}")
print(f"🔵 Bluetooth ESP32: {'Habilitado' if ESP32_ENABLED else 'Deshabilitado'}")


# ============================================
# MODELOS DE DATOS
# ============================================

class EvaluacionRequest(BaseModel):
    """Modelo para la petición de evaluación"""
    texto_modelo: str
    texto_nino: str
    umbral: float = 0.6


class BluetoothConfig(BaseModel):
    """Configuración del ESP32"""
    enabled: bool
    port: Optional[str] = None  # Puerto COM del ESP32 (ej: "COM5")
    baudrate: Optional[int] = 115200


class QuizRequest(BaseModel):
    """Modelo para la petición de generación de quiz"""
    title_correct: str
    caption: str


class QuizValidationRequest(BaseModel):
    """Modelo para validación de respuesta de quiz"""
    respuesta_usuario: str
    respuesta_correcta: str


# ============================================
# FUNCIONES BLUETOOTH
# ============================================

def esp32_connection_thread():
    """
    Thread que mantiene la conexión persistente con el ESP32.
    Se reconecta automáticamente si se pierde la conexión.
    """
    global esp32_serial, esp32_connected
    
    if not ESP32_ENABLED:
        print("⚠️ ESP32 deshabilitado - thread no iniciado")
        return
    
    print(f"\n--- 🔵 Iniciando Bucle de Conexión a {ESP32_PORT} ---")
    print("Esperando conexión con el ESP32...")
    
    intentos = 0
    
    while ESP32_ENABLED:
        try:
            # Intentamos abrir el puerto
            esp32_serial = serial.Serial(ESP32_PORT, ESP32_BAUDRATE, timeout=1)
            
            # --- BLOQUE DE CONEXIÓN EXITOSA ---
            print("\n" + "="*40)
            print(f"✅ ¡CONEXIÓN EXITOSA! Puerto {ESP32_PORT} abierto.")
            print("Esperando 2 segundos para estabilizar la conexión...")
            print("="*40 + "\n")
            
            # Esperamos un momento para asegurar que el canal Bluetooth esté listo
            time.sleep(2)
            
            # --- ENVIAMOS LA 'b' INICIAL ---
            print(">> Enviando comando inicial 'b' al ESP32...")
            esp32_serial.write(b'b')
            print(">> 'b' enviada correctamente.")
            
            esp32_connected = True
            
            # Bucle para mantener la conexión viva
            while ESP32_ENABLED and esp32_serial and esp32_serial.is_open:
                try:
                    # KeepAlive para que Windows no cierre el puerto por inactividad
                    esp32_serial.write(b'KeepAlive\n')
                    
                    if esp32_serial.in_waiting > 0:
                        line = esp32_serial.readline().decode('utf-8', errors='ignore').strip()
                        if line:  # Solo mostrar si hay contenido
                            print(f"📨 ESP32 dice: {line}")
                    
                    time.sleep(1)
                    
                except serial.SerialException:
                    print("\n⚠️ Conexión perdida con ESP32. Reconectando...")
                    esp32_connected = False
                    break
                except Exception as e:
                    print(f"\n⚠️ Error en KeepAlive: {str(e)}")
                    esp32_connected = False
                    break
            
            # Cerrar el puerto si salimos del bucle interno
            if esp32_serial and esp32_serial.is_open:
                esp32_serial.close()
                esp32_connected = False
                
        except serial.SerialException:
            intentos += 1
            if intentos % 10 == 1:  # Mostrar mensaje cada 10 intentos
                print(f"\r🔍 Buscando dispositivo... (Intento {intentos})", end="")
            time.sleep(2)
            
        except Exception as e:
            print(f"\n❌ Error inesperado: {str(e)}")
            time.sleep(2)


async def send_to_esp32(message: str):
    """
    Envía un mensaje al ESP32 usando la conexión persistente.
    
    Args:
        message: 'b' para correcto, 'm' para incorrecto
    """
    global esp32_serial, esp32_connected
    
    if not ESP32_ENABLED:
        print("⚠️ ESP32 deshabilitado - no se envía señal")
        return False
    
    if not esp32_connected or not esp32_serial or not esp32_serial.is_open:
        print(f"❌ ESP32 no conectado - no se puede enviar '{message}'")
        return False
    
    try:
        print(f"📤 Enviando '{message}' al ESP32...")
        esp32_serial.write(message.encode())
        print(f"✅ Mensaje '{message}' enviado al ESP32")
        return True
        
    except serial.SerialException as e:
        print(f"❌ Error de comunicación serial: {str(e)}")
        esp32_connected = False
        return False
    except Exception as e:
        print(f"❌ Error enviando a ESP32: {str(e)}")
        return False


# ============================================
# ENDPOINTS DEL GATEWAY
# ============================================

@app.get("/")
def root():
    return {
        "message": "API Gateway funcionando",
        "endpoints": {
            "predict": "POST /predict - Genera caption para una imagen (proxy al servidor ML)",
            "evaluate": "POST /evaluate - Evalúa respuesta y controla ESP32",
            "generate_quiz": "POST /generate-quiz - Genera quiz de opción múltiple",
            "validate_quiz": "POST /validate-quiz - Valida respuesta del quiz",
            "validar_reto": "POST /validar-reto - Valida imagen en juego interactivo",
            "health": "GET /health - Verifica estado del sistema",
            "configure_esp32": "POST /configure_esp32 - Configura conexión ESP32"
        }
    }


@app.get("/health")
async def health_check():
    """Verifica estado del gateway y del servidor ML"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{MODEL_SERVER_URL}/health")
            ml_server_status = response.json()
        
        return {
            "gateway_status": "healthy",
            "ml_server_status": ml_server_status.get("status", "unknown"),
            "esp32_enabled": ESP32_ENABLED,
            "esp32_connected": esp32_connected,
            "esp32_port": ESP32_PORT if ESP32_ENABLED else None
        }
    except Exception as e:
        return {
            "gateway_status": "healthy",
            "ml_server_status": "error",
            "error": str(e),
            "esp32_enabled": ESP32_ENABLED,
            "esp32_connected": esp32_connected,
            "esp32_port": ESP32_PORT if ESP32_ENABLED else None
        }


@app.post("/predict")
async def predict_proxy(image: UploadFile = File(...)):
    """
    Proxy para /predict - Recibe imagen del celular y la envía al servidor ML
    """
    print(f"\n🔄 GATEWAY /predict - {image.filename}")
    
    try:
        # Leer la imagen
        image_bytes = await image.read()
        
        # Preparar el archivo para enviarlo al servidor ML
        files = {
            'image': (image.filename, image_bytes, image.content_type)
        }
        
        # Enviar al servidor ML
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/predict",
                files=files
            )
        
        # Verificar respuesta
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error del servidor ML: {response.text}"
            )
        
        result = response.json()
        print(f"✅ GATEWAY - Caption generado: {result['caption'][:50]}...")
        
        return JSONResponse(
            content=result,
            media_type="application/json; charset=utf-8"
        )
        
    except httpx.TimeoutException:
        print("❌ GATEWAY - Timeout conectando al servidor ML")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando al servidor ML"
        )
    except Exception as e:
        print(f"❌ GATEWAY - Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en gateway: {str(e)}"
        )


@app.post("/evaluate")
async def evaluate_proxy(request: EvaluacionRequest):
    """
    Proxy para /evaluate - Evalúa respuesta y envía señal al ESP32
    'b' si es correcta, 'm' si es incorrecta
    """
    print(f"\n🔍 GATEWAY /evaluate")
    print(f"   Modelo: {request.texto_modelo[:50]}...")
    print(f"   Niño: {request.texto_nino[:50]}...")
    
    try:
        # Enviar al servidor ML para evaluación
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/evaluate",
                json={
                    "texto_modelo": request.texto_modelo,
                    "texto_nino": request.texto_nino,
                    "umbral": request.umbral
                }
            )
        
        # Verificar respuesta
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error del servidor ML: {response.text}"
            )
        
        result = response.json()
        es_correcta = result.get('es_correcta', False)
        
        print(f"   Resultado: {'✅ CORRECTA' if es_correcta else '❌ INCORRECTA'}")
        
        # Enviar señal al ESP32 según el resultado
        esp32_sent = False
        if es_correcta:
            print("🔵 Enviando señal 'b' (correcto) al ESP32...")
            esp32_sent = await send_to_esp32("b")
        else:
            print("🔵 Enviando señal 'm' (incorrecto) al ESP32...")
            esp32_sent = await send_to_esp32("m")
        
        # Agregar info sobre el ESP32 en la respuesta
        result['esp32_signal_sent'] = esp32_sent
        result['esp32_message'] = 'b' if es_correcta else 'm'
        
        return JSONResponse(
            content=result,
            media_type="application/json; charset=utf-8"
        )
        
    except httpx.TimeoutException:
        print("❌ GATEWAY - Timeout conectando al servidor ML")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando al servidor ML"
        )
    except Exception as e:
        print(f"❌ GATEWAY - Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en gateway: {str(e)}"
        )
async def generate_quiz_proxy(request: QuizRequest):
    """
    Proxy para /generate-quiz - Genera un quiz de opción múltiple
    """
    print(f"\n🎯 GATEWAY /generate-quiz - Título: {request.title_correct}")
    
    try:
        # Enviar al servidor ML
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/generate-quiz",
                json={
                    "title_correct": request.title_correct,
                    "caption": request.caption
                }
            )
        
        # Verificar respuesta
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error del servidor ML: {response.text}"
            )
        
        result = response.json()
        print(f"✅ GATEWAY - Quiz generado con {len(result.get('choices', []))} opciones")
        
        return JSONResponse(
            content=result,
            media_type="application/json; charset=utf-8"
        )
        
    except httpx.TimeoutException:
        print("❌ GATEWAY - Timeout conectando al servidor ML")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando al servidor ML"
        )
    except Exception as e:
        print(f"❌ GATEWAY - Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en gateway: {str(e)}"
        )


@app.post("/validate-quiz")
async def validate_quiz_proxy(request: QuizValidationRequest):
    """
    Proxy para /validate-quiz - Valida la respuesta del usuario en el quiz
    """
    print(f"\n🔍 GATEWAY /validate-quiz - Respuesta: {request.respuesta_usuario}")
    
    try:
        # Enviar al servidor ML
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/validate-quiz",
                json={
                    "respuesta_usuario": request.respuesta_usuario,
                    "respuesta_correcta": request.respuesta_correcta
                }
            )
        
        # Verificar respuesta
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error del servidor ML: {response.text}"
            )
        
        result = response.json()
        es_correcta = result.get('es_correcta', False)
        
        print(f"   Resultado: {'✅ CORRECTA' if es_correcta else '❌ INCORRECTA'}")
        
        # Enviar señal al ESP32 según el resultado
        esp32_sent = False
        if es_correcta:
            print("🔵 Enviando señal 'b' (correcto) al ESP32...")
            esp32_sent = await send_to_esp32("b")
        else:
            print("🔵 Enviando señal 'm' (incorrecto) al ESP32...")
            esp32_sent = await send_to_esp32("m")
        
        # Agregar info sobre el ESP32 en la respuesta
        result['esp32_signal_sent'] = esp32_sent
        result['esp32_message'] = 'b' if es_correcta else 'm'
        
        return JSONResponse(
            content=result,
            media_type="application/json; charset=utf-8"
        )
        
    except httpx.TimeoutException:
        print("❌ GATEWAY - Timeout conectando al servidor ML")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando al servidor ML"
        )
    except Exception as e:
        print(f"❌ GATEWAY - Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en gateway: {str(e)}"
        )


@app.post("/validar-reto")
async def validar_reto_proxy(
    sujeto_solicitado: str,
    image: UploadFile = File(...),
    umbral: float = 0.7
):
    """
    Proxy para /validar-reto - Valida si la imagen corresponde al sujeto solicitado
    en el juego interactivo
    """
    print(f"\n🎮 GATEWAY /validar-reto - Solicitado: '{sujeto_solicitado}'")
    
    try:
        # Leer la imagen
        image_bytes = await image.read()
        
        # Preparar el archivo para enviarlo al servidor ML
        files = {
            'image': (image.filename, image_bytes, image.content_type)
        }
        
        # Preparar los datos del form
        data = {
            'sujeto_solicitado': sujeto_solicitado,
            'umbral': str(umbral)
        }
        
        # Enviar al servidor ML
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/validar-reto",
                files=files,
                data=data
            )
        
        # Verificar respuesta
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error del servidor ML: {response.text}"
            )
        
        result = response.json()
        es_correcto = result.get('es_correcto', False)
        
        print(f"   Detectado: '{result.get('sujeto_detectado', 'N/A')}'")
        print(f"   Resultado: {'✅ CORRECTO' if es_correcto else '❌ INCORRECTO'}")
        
        # Enviar señal al ESP32 según el resultado
        esp32_sent = False
        if es_correcto:
            print("🔵 Enviando señal 'b' (correcto) al ESP32...")
            esp32_sent = await send_to_esp32("b")
        else:
            print("🔵 Enviando señal 'm' (incorrecto) al ESP32...")
            esp32_sent = await send_to_esp32("m")
        
        # Agregar info sobre el ESP32 en la respuesta
        result['esp32_signal_sent'] = esp32_sent
        result['esp32_message'] = 'b' if es_correcto else 'm'
        
        return JSONResponse(
            content=result,
            media_type="application/json; charset=utf-8"
        )
        
    except httpx.TimeoutException:
        print("❌ GATEWAY - Timeout conectando al servidor ML")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando al servidor ML"
        )
    except Exception as e:
        print(f"❌ GATEWAY - Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en gateway: {str(e)}"
        )



@app.post("/configure_esp32")
async def configure_esp32(config: BluetoothConfig):
    """
    Configura la conexión con el ESP32
    """
    global ESP32_ENABLED, ESP32_PORT, ESP32_BAUDRATE
    
    ESP32_ENABLED = config.enabled
    if config.port:
        ESP32_PORT = config.port
    if config.baudrate:
        ESP32_BAUDRATE = config.baudrate
    
    print(f"\n🔧 Configuración ESP32 actualizada:")
    print(f"   Habilitado: {ESP32_ENABLED}")
    print(f"   Puerto COM: {ESP32_PORT}")
    print(f"   Baudrate: {ESP32_BAUDRATE}")
    
    return {
        "status": "success",
        "esp32_enabled": ESP32_ENABLED,
        "esp32_port": ESP32_PORT,
        "esp32_baudrate": ESP32_BAUDRATE
    }


@app.post("/test_esp32")
async def test_esp32():
    """
    Prueba la conexión con el ESP32 enviando un mensaje de prueba
    """
    if not ESP32_ENABLED:
        raise HTTPException(
            status_code=400,
            detail="ESP32 no habilitado. Usa /configure_esp32 primero."
        )
    
    print("\n🧪 Probando conexión ESP32...")
    success = await send_to_esp32("t")  # 't' de test
    
    if success:
        return {"status": "success", "message": "Señal de prueba enviada al ESP32"}
    else:
        raise HTTPException(
            status_code=500,
            detail="No se pudo enviar señal al ESP32"
        )


@app.get("/ping")
def ping():
    """Endpoint simple para verificar conectividad del gateway"""
    return {"message": "pong", "status": "gateway_running"}


if __name__ == "__main__":
    import uvicorn
    
    # Iniciar el thread de conexión ESP32 si está habilitado
    if ESP32_ENABLED:
        esp32_thread = threading.Thread(target=esp32_connection_thread, daemon=True)
        esp32_thread.start()
        print(f"🔵 Thread de conexión ESP32 iniciado en {ESP32_PORT}")
    
    print("\n" + "="*50)
    print("🌐 Iniciando API Gateway en http://0.0.0.0:8001")
    print("="*50 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8001)
