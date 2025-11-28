# main.py - FastAPI con configuración probada Python 3.11.9
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
import io
import json
import wave
import tempfile
import os
from blip import quick_generate

app = FastAPI(
    title="BLIP Caption API", 
    description="API de generación de captions con BLIP - Python 3.11.9 + Transformers 4.53.2",
    version="1.0.0"
)

print("🚀 BLIP Caption API iniciada")
print("📋 Configuración: Python 3.11.9 + Transformers 4.53.2")
print("🎯 El modelo se cargará automáticamente al primer uso")


@app.on_event("startup")
async def startup_event():
    """Precargar el modelo al iniciar el servidor"""
    try:
        print("⏳ Precargando modelo BLIP...")
        # Importar directamente desde el módulo
        from blip.generation import get_global_generator
        get_global_generator()  # Esto carga el modelo en memoria
        print("✅ Modelo BLIP precargado exitosamente")
    except Exception as e:
        print(f"⚠️ Error precargando modelo: {e}")
        print("💡 El modelo se cargará en la primera petición")


@app.get("/")
def root():
    return {
        "message": "API de BLIP funcionando. Usa POST /predict para enviar una imagen.",
        "endpoints": {
            "predict": "POST /predict - Genera caption para una imagen",
            "health": "GET /health - Verifica estado del modelo"
        }
    }


@app.get("/health")
def health_check():
    """Endpoint para verificar que el modelo esté cargado"""
    try:
        from blip.generation import get_global_generator
        generator = get_global_generator()
        return {
            "status": "healthy",
            "model_loaded": True,
            "message": "Modelo BLIP listo para generar captions"
        }
    except Exception as e:
        return {
            "status": "error",
            "model_loaded": False,
            "error": str(e)
        }


@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    print(f"\n🔄 Nueva petición recibida")
    print(f"📄 Archivo: {image.filename}")
    print(f"📋 Content-Type: {image.content_type}")
    print(f"📏 Tamaño: {image.size if hasattr(image, 'size') else 'desconocido'}")
    
    # Validar tipo de archivo (aceptar todos los formatos comunes)
    allowed_types = [
        "image/png", 
        "image/jpeg", 
        "image/jpg", 
        "image/pjpeg",  # IE JPEG
        "application/octet-stream"  # Fallback para móviles
    ]
    
    # Verificar por extensión si el content-type no es reconocido
    if image.content_type not in allowed_types:
        if image.filename and any(image.filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png']):
            print("⚠️ Content-type no reconocido pero extensión válida, continuando...")
        else:
            error_msg = f"Formato no soportado. Recibido: '{image.content_type}'. Archivo: '{image.filename}'"
            print(f"❌ {error_msg}")
            raise HTTPException(
                status_code=400,
                detail=error_msg,
            )
    
    print("✅ Formato de archivo válido")

    # Leer bytes del archivo subido
    file_bytes = await image.read()

    # Abrir la imagen con PIL
    try:
        pil_image = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="No se pudo abrir la imagen. Verifica que el archivo sea una imagen válida.",
        )

    # Generar caption usando la configuración probada que funciona
    try:
        import time
        start_time = time.time()
        
        print(f"🤖 Generando caption para imagen {pil_image.size}...")
        caption = quick_generate(pil_image)
        
        processing_time = time.time() - start_time
        print(f"✅ Caption generado en {processing_time:.2f}s: {len(caption)} caracteres")
        
        return JSONResponse(content={
            "caption": caption,
            "status": "success",
            "length": len(caption),
            "processing_time_seconds": round(processing_time, 2),
            "image_size": list(pil_image.size)
        })
        
    except Exception as e:
        print(f"❌ Error generando caption: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error generando caption: {str(e)}"
        )


@app.post("/test-upload")
async def test_upload(image: UploadFile = File(...)):
    """Endpoint de prueba para verificar que se reciban las imágenes correctamente"""
    file_size = len(await image.read())
    return {
        "filename": image.filename,
        "content_type": image.content_type,
        "size": file_size,
        "status": "received_successfully",
        "message": f"Imagen '{image.filename}' recibida correctamente ({file_size} bytes)"
    }


@app.get("/ping")
def ping():
    """Endpoint simple para verificar conectividad"""
    return {"message": "pong", "status": "server_running"}


@app.post("/speech-to-text")
async def speech_to_text(audio: UploadFile = File(...)):
    """Endpoint para convertir audio a texto usando Vosk"""
    print(f"\n🎤 Nueva petición de audio recibida")
    print(f"📄 Archivo: {audio.filename}")
    print(f"📋 Content-Type: {audio.content_type}")
    
    # Validar formato de audio
    allowed_audio_types = [
        "audio/wav",
        "audio/wave", 
        "audio/x-wav",
        "audio/mpeg",
        "audio/mp3",
        "application/octet-stream"  # Fallback
    ]
    
    if audio.content_type not in allowed_audio_types:
        if audio.filename and any(audio.filename.lower().endswith(ext) for ext in ['.wav', '.mp3', '.m4a']):
            print("⚠️ Content-type de audio no reconocido pero extensión válida, continuando...")
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Formato de audio no soportado. Recibido: {audio.content_type}. Archivo: {audio.filename}",
            )
    
    print("✅ Formato de audio válido")
    
    try:
        # Guardar audio en archivo temporal
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_audio:
            audio_data = await audio.read()
            temp_audio.write(audio_data)
            temp_audio_path = temp_audio.name
        
        print(f"💾 Audio guardado temporalmente en: {temp_audio_path}")
        
        # Procesar con Vosk
        import time
        start_time = time.time()
        
        text_result = process_audio_with_vosk(temp_audio_path)
        
        processing_time = time.time() - start_time
        print(f"✅ Audio procesado en {processing_time:.2f}s")
        
        # Limpiar archivo temporal
        os.unlink(temp_audio_path)
        
        return JSONResponse(content={
            "text": text_result,
            "status": "success",
            "processing_time_seconds": round(processing_time, 2),
            "confidence": "high"  # Vosk no devuelve confidence fácilmente
        })
        
    except Exception as e:
        print(f"❌ Error procesando audio: {str(e)}")
        # Limpiar archivo temporal si existe
        if 'temp_audio_path' in locals() and os.path.exists(temp_audio_path):
            os.unlink(temp_audio_path)
        
        raise HTTPException(
            status_code=500,
            detail=f"Error procesando audio: {str(e)}"
        )


def process_audio_with_vosk(audio_file_path):
    """Procesa audio usando el modelo Vosk"""
    try:
        import vosk
        import json
        
        # Ruta al modelo Vosk
        model_path = r"C:\Users\EleXc\Desktop\tesis_app\vosk-model-small-es-0.42"
        
        if not os.path.exists(model_path):
            raise Exception(f"Modelo Vosk no encontrado en: {model_path}")
        
        # Cargar modelo
        print("🔄 Cargando modelo Vosk...")
        model = vosk.Model(model_path)
        rec = vosk.KaldiRecognizer(model, 16000)
        
        # Leer archivo de audio
        with wave.open(audio_file_path, 'rb') as wf:
            # Verificar formato
            if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getframerate() != 16000:
                print("⚠️ Formato de audio no óptimo para Vosk (esperado: mono, 16kHz, 16-bit)")
            
            # Procesar audio en chunks
            results = []
            while True:
                data = wf.readframes(4000)
                if len(data) == 0:
                    break
                if rec.AcceptWaveform(data):
                    result = json.loads(rec.Result())
                    if result.get('text'):
                        results.append(result['text'])
            
            # Resultado final
            final_result = json.loads(rec.FinalResult())
            if final_result.get('text'):
                results.append(final_result['text'])
        
        # Combinar todos los resultados
        full_text = ' '.join(results).strip()
        
        if not full_text:
            return "No se detectó ningún texto en el audio"
        
        return full_text
        
    except ImportError:
        raise Exception("Vosk no está instalado. Instala con: pip install vosk")
    except Exception as e:
        raise Exception(f"Error en Vosk: {str(e)}")


# ============================================
# ENDPOINT DE EVALUACIÓN
# ============================================

class EvaluacionRequest(BaseModel):
    """Modelo para la petición de evaluación"""
    texto_modelo: str
    texto_nino: str
    umbral: float = 0.6


@app.post("/evaluate")
async def evaluate(request: EvaluacionRequest):
    """
    Endpoint para evaluar si la respuesta del niño es correcta.
    
    - texto_modelo: El caption generado por BLIP
    - texto_nino: El texto reconocido de la voz del niño
    - umbral: Umbral de similitud (default: 0.6)
    
    Retorna:
    - mensaje: "¡Felicidades, respuesta correcta!" o "¡Inténtalo de nuevo!"
    - es_correcta: True/False
    - detalles: Información adicional sobre la evaluación
    """
    print(f"\n🔍 Nueva petición de evaluación recibida")
    print(f"📝 Texto modelo: {request.texto_modelo}")
    print(f"🎤 Texto niño: {request.texto_nino}")
    print(f"📊 Umbral: {request.umbral}")
    
    try:
        from evaluador import evaluar_respuesta
        
        import time
        start_time = time.time()
        
        # Evaluar la respuesta
        resultado = evaluar_respuesta(
            texto_modelo=request.texto_modelo,
            texto_nino=request.texto_nino,
            umbral=request.umbral
        )
        
        processing_time = time.time() - start_time
        
        # Determinar el mensaje según el resultado
        if resultado['es_correcta']:
            mensaje = "¡Felicidades, respuesta correcta!"
            print(f"✅ Respuesta correcta - Similitud: {resultado['similitud']:.4f}")
        else:
            mensaje = "¡Inténtalo de nuevo!"
            print(f"❌ Respuesta incorrecta - Similitud: {resultado['similitud']:.4f}")
        
        return JSONResponse(content={
            "mensaje": mensaje,
            "es_correcta": resultado['es_correcta'],
            "detalles": {
                "sujeto_modelo": resultado['sujeto_modelo'],
                "sujeto_nino": resultado['sujeto_nino'],
                "sujeto_igual": resultado['sujeto_igual'],
                "similitud": round(resultado['similitud'], 4),
                "umbral": resultado['umbral']
            },
            "processing_time_seconds": round(processing_time, 2)
        })
        
    except ImportError as e:
        print(f"❌ Error: Módulo no disponible: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Evaluador no disponible. Instala: pip install sentence-transformers spacy && python -m spacy download es_core_news_sm"
        )
    except Exception as e:
        print(f"❌ Error evaluando respuesta: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error evaluando respuesta: {str(e)}"
        )
