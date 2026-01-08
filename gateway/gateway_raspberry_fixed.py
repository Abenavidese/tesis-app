# gateway_raspberry.py - API Gateway para Raspberry Pi - Comunicación con ESP32
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
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
    title="API Gateway - Tesis App (Raspberry Pi)",
    description="Gateway para rutear peticiones entre celular, servidor ML y ESP32 (Raspberry Pi)",
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

# --- CONFIGURACIÓN ESP32 (Bluetooth) ---
PUERTO_ESP32 = '/dev/rfcomm0'  
ESP32_BAUDRATE = 115200
ESP32_ENABLED = True  # Cambia a False si no quieres usar ESP32

# --- CONFIGURACIÓN NEXTION (UART) ---
NEXTION_PORT = "/dev/serial0"   # UART del Raspberry Pi
NEXTION_BAUD = 9600             # Baud rate de Nextion
NEXTION_ENABLED = True          # Cambia a False si no quieres usar Nextion

# Páginas de Nextion
PAGE_MAIN = "page0"   # página principal/inicio
PAGE_WIN = "page2"    # ganaste
PAGE_LOSE = "page3"   # perdiste

# Variables globales para la conexión serial persistente ESP32
esp32_serial = None
esp32_thread = None
esp32_connected = False

# Variables globales para Nextion
nextion_serial = None
nextion_lock = None  # Se inicializa en startup

print("🚀 API Gateway Raspberry Pi iniciado")
print(f"📡 Servidor ML: {MODEL_SERVER_URL}")
print(f"🔵 Bluetooth ESP32: {'Habilitado' if ESP32_ENABLED else 'Deshabilitado'}")
print(f"🟣 Nextion Display: {'Habilitado' if NEXTION_ENABLED else 'Deshabilitado'}")


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
    port: Optional[str] = None  # Puerto COM del ESP32 (ej: "/dev/rfcomm0")
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
    
    print(f"\n--- Iniciando Bucle de Conexión en RASPBERRY ({PUERTO_ESP32}) ---")
    print("Esperando conexión con el ESP32...")
    
    intentos = 0
    
    while ESP32_ENABLED:
        try:
            # Intentamos abrir el puerto
            ser = serial.Serial(PUERTO_ESP32, ESP32_BAUDRATE, timeout=1)
            
            # --- BLOQUE DE CONEXIÓN EXITOSA ---
            print("\n" + "="*40)
            print(f"¡CONEXIÓN EXITOSA! Puerto {PUERTO_ESP32} abierto.")
            print("Esperando 2 segundos...")
            print("="*40 + "\n")
            
            # Esperamos un momento para asegurar que el canal Bluetooth esté listo
            time.sleep(2)
            
            # --- ENVIAMOS LA 'm' INICIAL ---
            print(">> Enviando 'm'...")
            ser.write(b'm')
            print(">> 'm' enviada correctamente.")
            
            esp32_connected = True
            esp32_serial = ser
            
            # Bucle para mantener la conexión viva
            while ESP32_ENABLED and ser and ser.is_open:
                try:
                    # KeepAlive para mantener la conexión
                    ser.write(b'KeepAlive\n')
                    
                    if ser.in_waiting > 0:
                        line = ser.readline().decode('utf-8', errors='ignore').strip()
                        if line:  # Solo mostrar si hay contenido
                            print(f"ESP32 dice: {line}")
                    
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
            if ser and ser.is_open:
                ser.close()
                esp32_connected = False
                
        except serial.SerialException as e:
            intentos += 1
            print(f"\rError conectando (Intento {intentos}): {e}")
            # A veces en Linux ayuda liberar el puerto si falló
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


def _send_nextion_sync(cmd: str) -> bool:
    """
    Envía un comando a Nextion por Serial (versión síncrona).
    Nextion exige terminar con: 0xFF 0xFF 0xFF
    """
    global nextion_serial
    
    if not NEXTION_ENABLED:
        print("⚠️ Nextion deshabilitado - no se envía comando")
        return False
    
    try:
        # Abrir puerto solo para este comando (más robusto)
        with serial.Serial(NEXTION_PORT, NEXTION_BAUD, timeout=1) as ser:
            ser.write(cmd.encode("ascii"))
            ser.write(b"\xff\xff\xff")  # Terminador requerido por Nextion
            ser.flush()
            print(f"✅ Comando Nextion enviado: {cmd}")
            return True
    except Exception as e:
        print(f"❌ Nextion error enviando '{cmd}': {e}")
        return False


async def send_to_nextion(cmd: str) -> bool:
    """
    Versión async para no bloquear FastAPI.
    Envía comando a Nextion.
    """
    try:
        result = await asyncio.to_thread(_send_nextion_sync, cmd)
        return result
    except Exception as e:
        print(f"❌ Error async enviando a Nextion: {e}")
        return False


async def show_result_and_return(is_correct: bool):
    """
    Muestra la página de resultado en Nextion (ganaste/perdiste)
    y después de 7 segundos regresa a la página principal.
    
    Args:
        is_correct: True para mostrar página de ganaste, False para perdiste
    """
    # Mostrar página de resultado
    page = PAGE_WIN if is_correct else PAGE_LOSE
    cmd = f"page {page}"
    await send_to_nextion(cmd)
    
    # Esperar 7 segundos en segundo plano
    async def return_to_main():
        await asyncio.sleep(7)
        await send_to_nextion(f"page {PAGE_MAIN}")
        print(f"🟣 Nextion: Regresando a {PAGE_MAIN} después de 7 segundos")
    
    # Ejecutar en background sin bloquear la respuesta
    asyncio.create_task(return_to_main())


# ============================================
# ENDPOINTS DEL GATEWAY
# ============================================

@app.get("/")
def root():
    return {
        "message": "API Gateway Raspberry Pi funcionando",
        "endpoints": {
            "predict": "POST /predict - Genera caption para una imagen (proxy al servidor ML)",
            "evaluate": "POST /evaluate - Evalúa respuesta y controla ESP32",
            "generate_quiz": "POST /generate-quiz - Genera quiz de opción múltiple",
            "validate_quiz": "POST /validate-quiz - Valida respuesta del quiz",
            "validar_reto": "POST /validar-reto - Valida imagen en juego interactivo",
            "validar_caracteristicas": "POST /validar-caracteristicas - Juego de características para niños",
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
            "esp32_port": PUERTO_ESP32 if ESP32_ENABLED else None,
            "nextion_enabled": NEXTION_ENABLED,
            "nextion_port": NEXTION_PORT if NEXTION_ENABLED else None
        }
    except Exception as e:
        return {
            "gateway_status": "healthy",
            "ml_server_status": "error",
            "error": str(e),
            "esp32_enabled": ESP32_ENABLED,
            "esp32_connected": esp32_connected,
            "esp32_port": PUERTO_ESP32 if ESP32_ENABLED else None,
            "nextion_enabled": NEXTION_ENABLED,
            "nextion_port": NEXTION_PORT if NEXTION_ENABLED else None
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
    Proxy para /evaluate - Evalúa respuesta y envía señal al ESP32 y a la pantalla Nextion

    ESP32:
      'b' si es correcta
      'm' si es incorrecta

    Nextion:
      page2 = ganaste
      page3 = perdiste
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
        es_correcta = result.get("es_correcta", False)

        print(f"   Resultado: {'✅ CORRECTA' if es_correcta else '❌ INCORRECTA'}")

        # Enviar señal al ESP32 según el resultado
        esp32_sent = False
        if es_correcta:
            print("🔵 Enviando señal 'b' (correcto) al ESP32...")
            esp32_sent = await send_to_esp32("b")
        else:
            print("🔵 Enviando señal 'm' (incorrecto) al ESP32...")
            esp32_sent = await send_to_esp32("m")

        # Enviar a Nextion: mostrar página de resultado y programar regreso a página principal
        nextion_page = PAGE_WIN if es_correcta else PAGE_LOSE
        print(f"🟣 Nextion: Mostrando {nextion_page} ({'GANASTE' if es_correcta else 'PERDISTE'})...")
        await show_result_and_return(es_correcta)

        # Agregar info sobre el ESP32 y Nextion en la respuesta
        result["esp32_signal_sent"] = esp32_sent
        result["esp32_message"] = "b" if es_correcta else "m"
        result["nextion_page_shown"] = nextion_page
        result["nextion_auto_return"] = True
        result["nextion_return_seconds"] = 7

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

@app.post("/generate-quiz")
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
        
        # Enviar a Nextion: mostrar página de resultado y programar regreso a página principal
        nextion_page = PAGE_WIN if es_correcta else PAGE_LOSE
        print(f"🟣 Nextion: Mostrando {nextion_page} ({'GANASTE' if es_correcta else 'PERDISTE'})...")
        await show_result_and_return(es_correcta)
        
        # Agregar info sobre el ESP32 y Nextion en la respuesta
        result['esp32_signal_sent'] = esp32_sent
        result['esp32_message'] = 'b' if es_correcta else 'm'
        result['nextion_page_shown'] = nextion_page
        result['nextion_auto_return'] = True
        result['nextion_return_seconds'] = 7
        
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
    image: UploadFile = File(...),
    sujeto_solicitado: str = Form(...),
    umbral: float = Form(0.7)
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
        
        # Enviar a Nextion: mostrar página de resultado y programar regreso a página principal
        nextion_page = PAGE_WIN if es_correcto else PAGE_LOSE
        print(f"🟣 Nextion: Mostrando {nextion_page} ({'GANASTE' if es_correcto else 'PERDISTE'})...")
        await show_result_and_return(es_correcto)
        
        # Agregar info sobre el ESP32 y Nextion en la respuesta
        result['esp32_signal_sent'] = esp32_sent
        result['esp32_message'] = 'b' if es_correcto else 'm'
        result['nextion_page_shown'] = nextion_page
        result['nextion_auto_return'] = True
        result['nextion_return_seconds'] = 7
        
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


@app.post("/validar-caracteristicas")
async def validar_caracteristicas_proxy(
    image: UploadFile = File(...),
    caracteristicas_seleccionadas: str = Form(...)
):
    """
    Proxy para /validar-caracteristicas - Juego de características para niños
    
    El niño selecciona características de una imagen y el sistema valida
    si son correctas comparándolas con las predichas por el modelo.
    
    Envía señales a ESP32 y Nextion según el resultado:
    - ESP32: 'b' si es correcto, 'm' si es incorrecto
    - Nextion: page2 (ganaste) o page3 (perdiste)
    """
    print(f"\n🎮 GATEWAY /validar-caracteristicas - Imagen: {image.filename}")
    print(f"   Características: {caracteristicas_seleccionadas[:100]}...")
    
    try:
        # Leer la imagen
        image_bytes = await image.read()
        
        # Preparar el archivo para enviarlo al servidor ML
        files = {
            'image': (image.filename, image_bytes, image.content_type)
        }
        
        # Preparar los datos del form
        data = {
            'caracteristicas_seleccionadas': caracteristicas_seleccionadas
        }
        
        # Enviar al servidor ML
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/validar-caracteristicas",
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
        porcentaje = result.get('porcentaje_acierto', 0)
        
        print(f"   Objeto: '{result.get('nombre_objeto', 'N/A')}'")
        print(f"   Porcentaje acierto: {porcentaje}%")
        print(f"   Resultado: {'✅ CORRECTO' if es_correcto else '❌ INCORRECTO'}")
        
        # Enviar señal al ESP32 según el resultado
        esp32_sent = False
        if es_correcto:
            print("🔵 Enviando señal 'b' (correcto) al ESP32...")
            esp32_sent = await send_to_esp32("b")
        else:
            print("🔵 Enviando señal 'm' (incorrecto) al ESP32...")
            esp32_sent = await send_to_esp32("m")
        
        # Enviar a Nextion: mostrar página de resultado y programar regreso a página principal
        nextion_page = PAGE_WIN if es_correcto else PAGE_LOSE
        print(f"🟣 Nextion: Mostrando {nextion_page} ({'GANASTE' if es_correcto else 'PERDISTE'})...")
        await show_result_and_return(es_correcto)
        
        # Agregar info sobre el ESP32 y Nextion en la respuesta
        result['esp32_signal_sent'] = esp32_sent
        result['esp32_message'] = 'b' if es_correcto else 'm'
        result['nextion_page_shown'] = nextion_page
        result['nextion_auto_return'] = True
        result['nextion_return_seconds'] = 7
        
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
    global ESP32_ENABLED, PUERTO_ESP32, ESP32_BAUDRATE
    
    ESP32_ENABLED = config.enabled
    if config.port:
        PUERTO_ESP32 = config.port
    if config.baudrate:
        ESP32_BAUDRATE = config.baudrate
    
    print(f"\n🔧 Configuración ESP32 actualizada:")
    print(f"   Habilitado: {ESP32_ENABLED}")
    print(f"   Puerto: {PUERTO_ESP32}")
    print(f"   Baudrate: {ESP32_BAUDRATE}")
    
    return {
        "status": "success",
        "esp32_enabled": ESP32_ENABLED,
        "esp32_port": PUERTO_ESP32,
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
        print(f"🔵 Thread de conexión ESP32 iniciado en {PUERTO_ESP32}")
    
    if NEXTION_ENABLED:
        print(f"🟣 Nextion habilitado en {NEXTION_PORT}")
    
    print("\n" + "="*50)
    print("🌐 Iniciando API Gateway Raspberry Pi en http://0.0.0.0:8001")
    print("="*50 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8001)
