# main.py - FastAPI con configuración probada Python 3.11.9
import os
# Forzar uso de CPU (GPU RTX 5070 Ti no compatible con PyTorch actual)
os.environ['CUDA_VISIBLE_DEVICES'] = ''

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
import io
from blip import quick_generate

app = FastAPI(
    title="BLIP Caption API", 
    description="API de generación de captions con BLIP - Python 3.11.9 + Transformers 4.53.2",
    version="1.0.0"
)

# Configurar CORS y encoding UTF-8
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
    # 🔥 OPTIMIZACIÓN: Logs reducidos para menos overhead
    print(f"\n🔄 /predict - {image.filename}")
    
    # Validar tipo de archivo (aceptar todos los formatos comunes)
    allowed_types = [
        "image/png", 
        "image/jpeg", 
        "image/jpg", 
        "image/pjpeg",
        "application/octet-stream"
    ]
    
    # Verificar por extensión si el content-type no es reconocido
    if image.content_type not in allowed_types:
        if not (image.filename and any(image.filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png'])):
            raise HTTPException(
                status_code=400,
                detail=f"Formato no soportado: {image.content_type}",
            )

    # 🔥 OPTIMIZACIÓN: Leer y procesar en un solo paso
    try:
        file_bytes = await image.read()
        # No convertir a RGB aquí - lo hace generate_caption() si es necesario
        pil_image = Image.open(io.BytesIO(file_bytes))
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail="Imagen inválida",
        )

    # Generar caption
    try:
        import time
        start_time = time.time()
        
        caption = quick_generate(pil_image)
        processing_time = time.time() - start_time
        
        # Extraer el título (texto antes de los dos puntos)
        title = caption.split(':', 1)[0].strip() if ':' in caption else caption.strip()
        
        print(f"✅ {processing_time:.2f}s - Título: {title} - {caption[:50]}...")
        
        return JSONResponse(
            content={
                "caption": caption,
                "title": title,
                "status": "success",
                "processing_time_seconds": round(processing_time, 2)
            },
            media_type="application/json; charset=utf-8"
        )
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error generando caption: {str(e)}"
        )


@app.get("/ping")
def ping():
    """Endpoint simple para verificar conectividad"""
    return {"message": "pong", "status": "server_running"}


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
    print(f"\n🔍 /evaluate - Umbral: {request.umbral}")
    
    try:
        from activities import evaluar_respuesta
        
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
            print(f"✅ {processing_time:.2f}s - Similitud: {resultado['similitud']:.3f}")
        else:
            mensaje = "¡Inténtalo de nuevo!"
            print(f"❌ {processing_time:.2f}s - Similitud: {resultado['similitud']:.3f}")
        
        return JSONResponse(
            content={
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
            },
            media_type="application/json; charset=utf-8"
        )
        
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


# ============================================
# ENDPOINT DE JUEGO INTERACTIVO
# ============================================

class ValidarRetoRequest(BaseModel):
    """Modelo para validación de reto interactivo"""
    sujeto_solicitado: str
    umbral: float = 0.7


@app.post("/validar-reto")
async def validar_reto(
    image: UploadFile = File(...),
    sujeto_solicitado: str = Form(...),
    umbral: float = Form(0.7)
):
    """
    Valida si la imagen corresponde al sujeto solicitado en el juego interactivo.
    
    Flujo:
    1. Recibe imagen y sujeto solicitado (ej: "caballo", "burro")
    2. Genera descripción completa con BLIP
    3. Extrae el sujeto de la descripción
    4. Compara con el sujeto solicitado
    5. Devuelve: correcto, sujeto_detectado, descripcion_completa
    
    Args:
    - image: Imagen a analizar
    - sujeto_solicitado: El sujeto que se le pidió al niño (ej: "caballo")
    - umbral: Umbral de similitud para validación (default: 0.7)
    
    Returns:
    - es_correcto: True si el sujeto detectado coincide con el solicitado
    - sujeto_solicitado: Sujeto que se le pidió al niño
    - sujeto_detectado: Sujeto extraído de la imagen
    - descripcion_completa: Caption completo generado por BLIP
    - similitud: Similitud semántica entre los sujetos
    """
    print(f"\n🎮 /validar-reto - Solicitado: '{sujeto_solicitado}'")
    
    try:
        # 1. Validar imagen
        file_bytes = await image.read()
        pil_image = Image.open(io.BytesIO(file_bytes))
        
        # 2. Generar descripción completa con BLIP
        import time
        start_time = time.time()
        
        descripcion_completa = quick_generate(pil_image)
        
        # 3. Extraer sujeto de la descripción
        from activities.evaluator_game import obtener_sujeto, similitud_semantica
        
        sujeto_detectado = obtener_sujeto(descripcion_completa)
        
        # 4. Comparar sujetos
        if sujeto_detectado and sujeto_solicitado:
            # Normalizar para comparación
            sujeto_solicitado_norm = sujeto_solicitado.lower().strip()
            sujeto_detectado_norm = sujeto_detectado.lower().strip()
            
            # Comparación exacta o similitud semántica
            if sujeto_solicitado_norm == sujeto_detectado_norm:
                es_correcto = True
                similitud = 1.0
            else:
                similitud = similitud_semantica(sujeto_solicitado_norm, sujeto_detectado_norm)
                es_correcto = similitud >= umbral
        else:
            es_correcto = False
            similitud = 0.0
        
        processing_time = time.time() - start_time
        
        # 5. Preparar respuesta
        mensaje = "¡Correcto! 🎉" if es_correcto else "¡Inténtalo de nuevo!"
        
        print(f"{'✅' if es_correcto else '❌'} {processing_time:.2f}s - Detectado: '{sujeto_detectado}' - Similitud: {similitud:.3f}")
        
        return JSONResponse(
            content={
                "es_correcto": es_correcto,
                "mensaje": mensaje,
                "sujeto_solicitado": sujeto_solicitado,
                "sujeto_detectado": sujeto_detectado,
                "descripcion_completa": descripcion_completa,
                "similitud": round(similitud, 4),
                "umbral": umbral,
                "processing_time_seconds": round(processing_time, 2)
            },
            media_type="application/json; charset=utf-8"
        )
        
    except Exception as e:
        print(f"❌ Error validando reto: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error validando reto: {str(e)}"
        )


# ============================================
# ENDPOINT DE QUIZ
# ============================================

class QuizRequest(BaseModel):
    """Modelo para la petición de generación de quiz"""
    title_correct: str
    caption: str


class QuizValidationRequest(BaseModel):
    """Modelo para validación de respuesta de quiz"""
    respuesta_usuario: str
    respuesta_correcta: str


@app.post("/generate-quiz")
async def generate_quiz(request: QuizRequest):
    """
    Genera un quiz de opción múltiple basado en el título de la descripción.
    
    - title_correct: Título correcto de la imagen (ej: "Higiene")
    - caption: Caption completo generado por BLIP
    
    Retorna:
    - question: Pregunta del quiz
    - caption: Caption completo
    - choices: Lista de 4 opciones mezcladas
    - answer: Respuesta correcta
    """
    print(f"\n🎯 /generate-quiz - Título: {request.title_correct}")
    
    try:
        from activities import generar_quiz
        
        import time
        start_time = time.time()
        
        # Generar quiz
        quiz_data = generar_quiz(
            title_correct=request.title_correct,
            caption=request.caption
        )
        
        processing_time = time.time() - start_time
        
        print(f"✅ {processing_time:.2f}s - Quiz generado con {len(quiz_data['choices'])} opciones")
        
        return JSONResponse(
            content={
                "question": quiz_data["question"],
                "caption": quiz_data["caption"],
                "choices": quiz_data["choices"],
                "answer": quiz_data["answer"],
                "processing_time_seconds": round(processing_time, 2)
            },
            media_type="application/json; charset=utf-8"
        )
        
    except ImportError as e:
        print(f"❌ Error: Módulo no disponible: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Módulo de quiz no disponible: {str(e)}"
        )
    except Exception as e:
        print(f"❌ Error generando quiz: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error generando quiz: {str(e)}"
        )


@app.post("/validate-quiz")
async def validate_quiz(request: QuizValidationRequest):
    """
    Valida la respuesta del usuario en el quiz.
    
    - respuesta_usuario: Opción seleccionada por el usuario
    - respuesta_correcta: Respuesta correcta
    
    Retorna:
    - es_correcta: True/False
    - respuesta_usuario: Respuesta del usuario
    - respuesta_correcta: Respuesta correcta
    - mensaje: Mensaje de feedback
    """
    print(f"\n🔍 /validate-quiz - Usuario: {request.respuesta_usuario}")
    
    try:
        from activities.quiz_game import validar_respuesta_quiz
        
        resultado = validar_respuesta_quiz(
            respuesta_usuario=request.respuesta_usuario,
            respuesta_correcta=request.respuesta_correcta
        )
        
        if resultado["es_correcta"]:
            print(f"✅ Respuesta correcta")
        else:
            print(f"❌ Respuesta incorrecta")
        
        return JSONResponse(
            content=resultado,
            media_type="application/json; charset=utf-8"
        )
        
    except Exception as e:
        print(f"❌ Error validando respuesta: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error validando respuesta: {str(e)}"
        )
