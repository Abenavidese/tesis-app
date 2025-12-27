# 🎮 Sistema de Actividades y Juegos Educativos

## 📁 Estructura

```
api/activities/
├── __init__.py           # Módulo principal
├── evaluator_game.py     # Juego 1: Evaluación de descripción
└── quiz_game.py          # Juego 2: Quiz de opción múltiple
```

## 🎯 Juegos Disponibles

### 1. Evaluador de Descripciones (`evaluator_game.py`)

Evalúa si la descripción del niño coincide con la descripción generada por BLIP.

**Endpoint**: `POST /evaluate`

**Request**:
```json
{
  "texto_modelo": "Un niño cepillándose los dientes",
  "texto_nino": "Niño lavando dientes",
  "umbral": 0.6
}
```

**Response**:
```json
{
  "mensaje": "¡Felicidades, respuesta correcta!",
  "es_correcta": true,
  "detalles": {
    "sujeto_modelo": "niño",
    "sujeto_nino": "niño",
    "sujeto_igual": true,
    "similitud": 0.85,
    "umbral": 0.6
  }
}
```

### 2. Quiz de Temas (`quiz_game.py`)

Genera preguntas de opción múltiple basadas en el título de la descripción.

**Endpoint**: `POST /generate-quiz`

**Request**:
```json
{
  "title_correct": "Higiene",
  "caption": "Higiene: aquí se puede ver a un niño cepillándose los dientes..."
}
```

**Response**:
```json
{
  "question": "¿Cuál es el tema correcto de la imagen?",
  "caption": "Higiene: aquí se puede ver...",
  "choices": ["Derecho a la salud", "Higiene", "Sistema digestivo", "Cuidar a la mascota"],
  "answer": "Higiene"
}
```

**Endpoint**: `POST /validate-quiz`

**Request**:
```json
{
  "respuesta_usuario": "Higiene",
  "respuesta_correcta": "Higiene"
}
```

**Response**:
```json
{
  "es_correcta": true,
  "respuesta_usuario": "Higiene",
  "respuesta_correcta": "Higiene",
  "mensaje": "¡Excelente! Tu respuesta es correcta."
}
```

## 🎨 Temas Disponibles (Distractores)

El quiz utiliza 80+ temas categorizados:

- **Salud y cuidado personal**: Higiene, Alimentación, Descanso...
- **Responsabilidades**: Ayudar en casa, Cuidar mascota, Reciclaje...
- **Valores sociales**: Familia, Amistad, Respeto, Solidaridad...
- **Derechos**: Educación, Salud, Alimentación, Vivienda...
- **Cuerpo humano**: Sistemas digestivo, respiratorio, circulatorio...
- **Naturaleza**: Animales, Plantas, Ecosistemas...
- **Geografía**: Montañas, Ríos, Islas, Volcanes...
- **Cultura**: Edificios históricos, Patrimonio, Fiestas...
- **Recreación**: Juegos, Deporte, Cumpleaños, Navidad...
- **Educación**: Escuela, Aula, Lectura, Escritura...

## 🔧 Uso en Python

```python
from activities import evaluar_respuesta, generar_quiz

# Juego 1: Evaluador
resultado = evaluar_respuesta(
    texto_modelo="Un perro en el jardín",
    texto_nino="Perro en patio",
    umbral=0.6
)
print(resultado['es_correcta'])

# Juego 2: Quiz
quiz = generar_quiz(
    title_correct="Higiene",
    caption="Higiene: aquí se puede ver..."
)
print(quiz['choices'])
```

## ⚙️ Configuración

### Variables de Entorno (`.env`)

```env
# Modelo BLIP
BLIP_MODEL_PATH=ruta/al/modelo
BLIP_DEVICE=cpu
BLIP_NUM_THREADS=4
BLIP_IMAGE_SIZE=384
```

### Dependencias

- `sentence-transformers`: Para similitud semántica
- `spacy`: Para análisis lingüístico
- `es_core_news_sm`: Modelo de español para spacy

```bash
pip install sentence-transformers spacy
python -m spacy download es_core_news_sm
```

## 🧪 Testing

```bash
# Test del evaluador
python -c "from activities import evaluar_respuesta; print(evaluar_respuesta('perro', 'perro', 0.6))"

# Test del quiz
python activities/quiz_game.py
```

## 📝 Notas

- El evaluador usa similitud semántica, no coincidencia exacta
- El quiz mezcla opciones aleatoriamente en cada generación
- Los distractores se seleccionan automáticamente de temas diferentes

---

✅ Sistema listo para usar en producción
