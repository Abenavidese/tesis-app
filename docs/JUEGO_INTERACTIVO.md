# Juego Interactivo - Documentación

## Endpoint: `/validar-reto`

Este endpoint permite crear un juego interactivo de 4 retos donde el niño debe identificar o capturar imágenes de objetos específicos.

## Descripción del Flujo

### Reto 1: Selección de Imagen
El frontend muestra 4 imágenes y pide "Elige el caballo"
- El niño selecciona una imagen
- Se envía al backend junto con el sujeto solicitado ("caballo")
- El backend valida si la imagen contiene el sujeto correcto

### Reto 2: Captura Rápida
El frontend dice "¡Rápido! Tómale una foto a un burro"
- El niño toma la foto
- Se envía al backend junto con el sujeto solicitado ("burro")
- El backend valida y **devuelve la descripción completa** para el minijuego

### Reto 3 y 4: Variantes
Puedes implementar variantes como:
- Capturar múltiples objetos en secuencia
- Límite de tiempo
- Completar frases basadas en la descripción

---

## Uso del Endpoint

### Request

**URL:** `POST http://localhost:8000/validar-reto`

**Content-Type:** `multipart/form-data`

**Parámetros:**
- `image` (file): La imagen a analizar
- `sujeto_solicitado` (string): El sujeto que se le pidió al niño (ej: "caballo", "burro", "león")
- `umbral` (float, opcional): Umbral de similitud (default: 0.7)

### Ejemplo con cURL

```bash
curl -X POST "http://localhost:8000/validar-reto" \
  -F "image=@foto.jpg" \
  -F "sujeto_solicitado=caballo" \
  -F "umbral=0.7"
```

### Ejemplo con Python

```python
import requests

url = "http://localhost:8000/validar-reto"

with open("foto.jpg", "rb") as f:
    files = {"image": f}
    data = {
        "sujeto_solicitado": "caballo",
        "umbral": 0.7
    }
    response = requests.post(url, files=files, data=data)
    result = response.json()
    
    print(f"¿Correcto? {result['es_correcto']}")
    print(f"Sujeto detectado: {result['sujeto_detectado']}")
    print(f"Descripción: {result['descripcion_completa']}")
```

### Ejemplo con Flutter/Dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> validarReto(
  File imagen, 
  String sujetoSolicitado
) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8000/validar-reto'),
  );
  
  // Agregar imagen
  request.files.add(
    await http.MultipartFile.fromPath('image', imagen.path)
  );
  
  // Agregar sujeto solicitado
  request.fields['sujeto_solicitado'] = sujetoSolicitado;
  request.fields['umbral'] = '0.7';
  
  // Enviar request
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return json.decode(responseData);
}

// Uso
void main() async {
  var resultado = await validarReto(
    File('/path/to/imagen.jpg'),
    'caballo'
  );
  
  if (resultado['es_correcto']) {
    print('¡Correcto! 🎉');
    print('Descripción: ${resultado['descripcion_completa']}');
  } else {
    print('¡Inténtalo de nuevo!');
    print('Detecté: ${resultado['sujeto_detectado']}');
  }
}
```

---

## Response

### Estructura de la Respuesta

```json
{
  "es_correcto": true,
  "mensaje": "¡Correcto! 🎉",
  "sujeto_solicitado": "caballo",
  "sujeto_detectado": "caballo",
  "descripcion_completa": "Animales domésticos: aquí se puede ver un caballo marrón en un campo verde",
  "similitud": 1.0,
  "umbral": 0.7,
  "processing_time_seconds": 1.23
}
```

### Campos de la Respuesta

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `es_correcto` | boolean | `true` si el sujeto detectado coincide con el solicitado |
| `mensaje` | string | Mensaje de feedback: "¡Correcto! 🎉" o "¡Inténtalo de nuevo!" |
| `sujeto_solicitado` | string | El sujeto que se le pidió al niño |
| `sujeto_detectado` | string | El sujeto extraído de la imagen por el modelo |
| `descripcion_completa` | string | Caption completo generado por BLIP (útil para minijuego de completar) |
| `similitud` | float | Similitud semántica entre los sujetos (0.0 - 1.0) |
| `umbral` | float | Umbral usado para la validación |
| `processing_time_seconds` | float | Tiempo de procesamiento en segundos |

---

## Ejemplos de Uso

### Reto 1: Selección (4 imágenes)

**Frontend:**
```
Pantalla: 4 imágenes [león, tigre, caballo, elefante]
Texto: "¿Cuál es el CABALLO? 🐴"
```

**Al seleccionar la imagen del caballo:**
```javascript
// Enviar al backend
POST /validar-reto
image: [imagen_caballo.jpg]
sujeto_solicitado: "caballo"

// Respuesta
{
  "es_correcto": true,
  "sujeto_detectado": "caballo",
  "descripcion_completa": "Animales domésticos: aquí se puede ver un caballo..."
}
```

### Reto 2: Captura Rápida

**Frontend:**
```
Pantalla: Cámara activa
Texto: "¡RÁPIDO! Tómale una foto a un BURRO 📸"
Timer: 10 segundos
```

**Al tomar la foto:**
```javascript
POST /validar-reto
image: [foto_tomada.jpg]
sujeto_solicitado: "burro"

// Respuesta
{
  "es_correcto": true,
  "sujeto_detectado": "burro",
  "descripcion_completa": "Animales domésticos: aquí se puede ver un burro gris comiendo pasto"
}

// Usar descripcion_completa para minijuego de completar:
// "Animales domésticos: aquí se puede ver un _____ gris comiendo _____"
```

### Reto 3: Minijuego de Completar

Usa `descripcion_completa` del Reto 2:

**Frontend:**
```
Texto completo: "Animales domésticos: aquí se puede ver un burro gris comiendo pasto"

Minijuego: Completa la frase
"Animales domésticos: aquí se puede ver un _____ gris comiendo _____"

Opciones:
- burro / pasto ✅
- caballo / agua
- perro / hueso
```

---

## Casos Especiales

### Sistemas del Cuerpo

Si el sujeto es un sistema del cuerpo humano, el backend detecta el sistema completo:

```javascript
POST /validar-reto
sujeto_solicitado: "sistema circulatorio"

// Respuesta
{
  "es_correcto": true,
  "sujeto_detectado": "sistema circulatorio",
  "descripcion_completa": "Sistema circulatorio: en esta imagen se observa el corazón y las venas..."
}
```

### Animales Prioritarios

El backend prioriza animales sobre palabras genéricas:

```javascript
// Imagen con texto: "Una variedad de ganado incluyendo vacas"
POST /validar-reto
sujeto_solicitado: "vaca"

// Respuesta
{
  "es_correcto": true,
  "sujeto_detectado": "vaca",  // No "variedad"
  "similitud": 1.0
}
```

---

## Errores Comunes

### Error 400: Formato no soportado
```json
{
  "detail": "Formato no soportado: application/pdf"
}
```
**Solución:** Enviar solo imágenes JPG, PNG o JPEG

### Error 500: Error generando caption
```json
{
  "detail": "Error generando caption: ..."
}
```
**Solución:** Verificar que la imagen sea válida y el servidor tenga el modelo cargado

---

## Tips de Implementación

### 1. Precarga de Imágenes
Para Reto 1 (selección), precarga 4 imágenes conocidas:
```python
# Backend: Generar 4 descripciones y guardar sujetos
imagenes = ["leon.jpg", "tigre.jpg", "caballo.jpg", "elefante.jpg"]
for img in imagenes:
    result = requests.post("/validar-reto", ...)
    # Guardar sujeto_detectado para validación rápida
```

### 2. Timer para Reto 2
```dart
// Flutter
Timer? _challengeTimer;

void startChallenge() {
  _challengeTimer = Timer(Duration(seconds: 10), () {
    // Tiempo agotado
    showDialog(...);
  });
}

void onPhotoTaken() async {
  _challengeTimer?.cancel();
  var result = await validarReto(...);
  // Mostrar resultado
}
```

### 3. Minijuego de Completar
```javascript
// Extraer palabras clave de descripcion_completa
function crearMinijuego(descripcion) {
  // "aquí se puede ver un burro gris comiendo pasto"
  const palabras = ["burro", "pasto"];
  
  // Reemplazar con espacios en blanco
  let textoConBlancos = descripcion;
  palabras.forEach(palabra => {
    textoConBlancos = textoConBlancos.replace(palabra, "_____");
  });
  
  return {
    texto: textoConBlancos,
    respuestas: palabras
  };
}
```

---

## Flujo Completo del Juego

```
[START] → Pantalla de bienvenida
    ↓
[RETO 1] → Mostrar 4 imágenes
    ↓ (Niño selecciona)
    ↓ POST /validar-reto
    ↓
[VALIDACIÓN 1] → ¿Correcto?
    ↓ (Sí)
    ↓
[RETO 2] → "¡Tómale foto a un burro!"
    ↓ (Niño toma foto)
    ↓ POST /validar-reto
    ↓
[VALIDACIÓN 2] → ¿Correcto?
    ↓ (Sí) + Guardar descripcion_completa
    ↓
[RETO 3] → Minijuego de completar
    ↓ (Usar descripcion_completa)
    ↓
[RETO 4] → Captura múltiple / Timer
    ↓
[FIN] → Pantalla de felicitaciones 🎉
```

---

## Configuración

### Ajustar Umbral de Similitud

Por defecto, el umbral es `0.7`. Puedes ajustarlo según la dificultad:

- **Fácil:** `umbral=0.5` (acepta similitudes bajas)
- **Normal:** `umbral=0.7` (default)
- **Difícil:** `umbral=0.9` (requiere coincidencia casi exacta)

```python
# Ejemplo: Modo fácil para niños pequeños
response = requests.post(
    "http://localhost:8000/validar-reto",
    files={"image": open("foto.jpg", "rb")},
    data={"sujeto_solicitado": "perro", "umbral": 0.5}
)
```

---

## Testing

### Test con cURL

```bash
# Test básico
curl -X POST "http://localhost:8000/validar-reto" \
  -F "image=@test_caballo.jpg" \
  -F "sujeto_solicitado=caballo"

# Test con umbral custom
curl -X POST "http://localhost:8000/validar-reto" \
  -F "image=@test_leon.jpg" \
  -F "sujeto_solicitado=león" \
  -F "umbral=0.8"
```

### Test con Python

```python
import requests

def test_validar_reto():
    url = "http://localhost:8000/validar-reto"
    
    tests = [
        ("test_caballo.jpg", "caballo", True),
        ("test_leon.jpg", "tigre", False),
        ("test_burro.jpg", "burro", True),
    ]
    
    for imagen, sujeto, esperado in tests:
        with open(imagen, "rb") as f:
            response = requests.post(
                url,
                files={"image": f},
                data={"sujeto_solicitado": sujeto}
            )
            result = response.json()
            
            assert result["es_correcto"] == esperado, \
                f"Test falló para {imagen}: esperado={esperado}, obtenido={result['es_correcto']}"
            
            print(f"✅ {imagen} - {sujeto}: {result['es_correcto']}")

if __name__ == "__main__":
    test_validar_reto()
```

---

## Próximos Pasos

1. ✅ Endpoint `/validar-reto` implementado
2. 🔲 Implementar frontend Flutter con 4 pantallas de retos
3. 🔲 Agregar timer y animaciones
4. 🔲 Implementar minijuego de completar frases
5. 🔲 Agregar sistema de puntuación
6. 🔲 Guardar progreso del niño en base de datos

---

## Soporte

Para dudas o problemas:
- Revisar logs del servidor: `python api/main.py`
- Verificar modelo cargado: `GET /health`
- Test de conectividad: `GET /ping`
