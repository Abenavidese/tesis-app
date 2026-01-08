# Juego de Características - Actividad 4

## Descripción

Esta es la cuarta actividad del sistema educativo. Es un juego interactivo donde el niño debe identificar las características de una imagen.

## Cómo Funciona

### Flujo del Juego

1. **Frontend muestra una imagen** al niño
2. **El niño selecciona características** de la imagen de una lista de opciones
3. **Se envía la imagen y las características** al backend
4. **El modelo de características predice** las características reales de la imagen
5. **Se comparan** las características seleccionadas vs las predichas
6. **Se retorna feedback**: "¡Correcto!" o "¡Inténtalo de nuevo!"

### Formato del Modelo

El modelo de características genera descripciones en el formato:
```
nombre, característica1, característica2, característica3
```

**Ejemplo:**
```
isla, porción de tierra aislada, rodeada completamente por agua, pequeña extensión
```

- **Primera parte (antes de la primera coma)**: Nombre del objeto
- **Resto (separado por comas)**: Características del objeto

## Endpoint API

### POST `/validar-caracteristicas`

Valida si las características seleccionadas por el niño son correctas.

#### Request

**Content-Type:** `multipart/form-data`

**Parámetros:**
- `image` (File, required): Imagen a analizar
- `caracteristicas_seleccionadas` (string, required): JSON string con lista de características
  - Ejemplo: `'["rodeada de agua", "aislada", "pequeña"]'`
- `umbral` (float, optional): Umbral de similitud (default: 0.7)

#### Response

**Content-Type:** `application/json; charset=utf-8`

**Campos:**
```json
{
  "es_correcto": true,
  "mensaje": "¡Perfecto! Todas las características son correctas 🎉",
  "nombre_objeto": "isla",
  "caracteristicas_modelo": [
    "porción de tierra aislada",
    "rodeada completamente por agua",
    "pequeña extensión"
  ],
  "caracteristicas_correctas": [
    "rodeada de agua",
    "aislada"
  ],
  "caracteristicas_incorrectas": [],
  "porcentaje_acierto": 100.0,
  "total_seleccionadas": 2,
  "total_correctas": 2,
  "detalles": [
    {
      "caracteristica_nino": "rodeada de agua",
      "caracteristica_modelo_match": "rodeada completamente por agua",
      "similitud": 0.8945,
      "es_correcta": true
    },
    {
      "caracteristica_nino": "aislada",
      "caracteristica_modelo_match": "porción de tierra aislada",
      "similitud": 0.7823,
      "es_correcta": true
    }
  ],
  "descripcion_completa": "isla, porción de tierra aislada, rodeada completamente por agua, pequeña extensión",
  "umbral": 0.7,
  "processing_time_seconds": 1.23
}
```

## Ejemplo de Uso

### Python (requests)

```python
import requests
import json

# Preparar datos
url = "http://localhost:8000/validar-caracteristicas"

# Características seleccionadas por el niño
caracteristicas = ["rodeada de agua", "aislada", "pequeña"]

# Preparar form data
files = {
    'image': open('isla.jpg', 'rb')
}
data = {
    'caracteristicas_seleccionadas': json.dumps(caracteristicas),
    'umbral': 0.7
}

# Hacer request
response = requests.post(url, files=files, data=data)
resultado = response.json()

# Mostrar resultado
if resultado['es_correcto']:
    print(f"✅ {resultado['mensaje']}")
    print(f"   Porcentaje: {resultado['porcentaje_acierto']}%")
else:
    print(f"❌ {resultado['mensaje']}")
    print(f"   Correctas: {resultado['caracteristicas_correctas']}")
    print(f"   Incorrectas: {resultado['caracteristicas_incorrectas']}")
```

### JavaScript (fetch)

```javascript
// Preparar datos
const formData = new FormData();
formData.append('image', imageFile); // File object
formData.append('caracteristicas_seleccionadas', JSON.stringify([
  "rodeada de agua",
  "aislada",
  "pequeña"
]));
formData.append('umbral', '0.7');

// Hacer request
fetch('http://localhost:8000/validar-caracteristicas', {
  method: 'POST',
  body: formData
})
.then(response => response.json())
.then(resultado => {
  if (resultado.es_correcto) {
    console.log(`✅ ${resultado.mensaje}`);
    console.log(`Porcentaje: ${resultado.porcentaje_acierto}%`);
  } else {
    console.log(`❌ ${resultado.mensaje}`);
    console.log('Correctas:', resultado.caracteristicas_correctas);
    console.log('Incorrectas:', resultado.caracteristicas_incorrectas);
  }
});
```

### cURL

```bash
curl -X POST "http://localhost:8000/validar-caracteristicas" \
  -F "image=@isla.jpg" \
  -F 'caracteristicas_seleccionadas=["rodeada de agua", "aislada"]' \
  -F "umbral=0.7"
```

## Criterios de Evaluación

### Similitud Semántica

El sistema usa **similitud semántica** para comparar características, no comparación exacta de texto. Esto significa que:

- ✅ "rodeada de agua" ≈ "rodeada completamente por agua" (similitud: 0.89)
- ✅ "aislada" ≈ "porción de tierra aislada" (similitud: 0.78)
- ❌ "tiene montañas" ≠ "rodeada de agua" (similitud: 0.12)

### Umbral de Similitud

- **Default: 0.7** (70% de similitud)
- Puedes ajustarlo según la dificultad deseada
- Valores más altos = más estricto
- Valores más bajos = más permisivo

### Criterio de Aprobación

El niño aprueba si:
- **Al menos 60% de las características seleccionadas son correctas**

Ejemplos:
- 2/2 correctas = 100% → ✅ Aprobado
- 2/3 correctas = 66% → ✅ Aprobado
- 1/3 correctas = 33% → ❌ Reprobado

## Configuración del Modelo

### ⚠️ IMPORTANTE: Configurar tu Modelo

El archivo `characteristics_model.py` es un **placeholder**. Debes actualizarlo con tu modelo real:

1. **Ubicación del modelo:**
   ```python
   MODEL_PATH = "path/to/your/characteristics/model"  # ⚠️ CAMBIAR ESTO
   ```

2. **Cargar el modelo:**
   ```python
   def __init__(self, model_path: str = MODEL_PATH):
       # Ejemplo para Hugging Face:
       from transformers import BlipProcessor, BlipForConditionalGeneration
       self.processor = BlipProcessor.from_pretrained(model_path)
       self.model = BlipForConditionalGeneration.from_pretrained(model_path)
       
       # O para modelo custom:
       self.model = torch.load(model_path)
       self.model.eval()
   ```

3. **Generar predicción:**
   ```python
   def generate(self, image: Image.Image) -> str:
       # Implementar tu lógica de inferencia
       inputs = self.processor(image, return_tensors="pt")
       out = self.model.generate(**inputs)
       caption = self.processor.decode(out[0], skip_special_tokens=True)
       return caption
   ```

## Testing

### Test del Módulo de Características

```bash
cd api/activities
python characteristics_game.py
```

Esto ejecutará tests de ejemplo con diferentes escenarios.

### Test del Modelo

```bash
cd api
python characteristics_model.py
```

Esto probará la carga y generación del modelo.

### Test del Endpoint

```bash
# Iniciar servidor
cd api
uvicorn main:app --reload

# En otra terminal, hacer request de prueba
curl -X POST "http://localhost:8000/validar-caracteristicas" \
  -F "image=@test_image.jpg" \
  -F 'caracteristicas_seleccionadas=["característica 1", "característica 2"]'
```

## Estructura de Archivos

```
api/
├── main.py                          # Endpoint /validar-caracteristicas
├── characteristics_model.py         # Modelo de características (⚠️ CONFIGURAR)
└── activities/
    ├── __init__.py                  # Exporta validar_juego_caracteristicas
    ├── characteristics_game.py      # Lógica del juego
    ├── evaluator_game.py            # Actividad 1
    └── quiz_game.py                 # Actividad 3
```

## Próximos Pasos

1. **Configurar el modelo de características** en `characteristics_model.py`
2. **Probar el endpoint** con imágenes de prueba
3. **Integrar con el frontend** para crear la interfaz del juego
4. **Ajustar el umbral** según la dificultad deseada

## Preguntas Frecuentes

### ¿Qué pasa si el modelo no genera el formato correcto?

El sistema es robusto y maneja casos edge:
- Si no hay comas, usa la descripción completa como nombre
- Si solo hay una parte, retorna lista vacía de características

### ¿Puedo usar características en inglés?

Sí, pero el modelo de similitud está optimizado para español (`paraphrase-multilingual-MiniLM-L12-v2`). Para mejor rendimiento en inglés, cambia el modelo en `characteristics_game.py`.

### ¿Cómo ajusto la dificultad?

Hay dos formas:
1. **Umbral de similitud**: Más alto = más difícil
2. **Porcentaje de aprobación**: Editar en `characteristics_game.py` línea 189 (actualmente 60%)
