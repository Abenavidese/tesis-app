# main.py - FastAPI con configuración probada Python 3.11.9
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
import io
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
