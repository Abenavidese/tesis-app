# Actividad 4: Juego de Características

## 📝 Descripción

Actividad educativa donde el niño debe identificar las características correctas de una imagen mostrada.

## 🎯 Objetivo

Desarrollar habilidades de observación y reconocimiento de características en los niños mediante un juego interactivo.

## 🎨 Diseño

- **Colores principales**: Morado (`#AB47BC`, `#8E24AA`)
- **Icono**: ✨ (estrella brillante)
- **Estilo**: Diseño infantil colorido y amigable

## 📁 Estructura de Archivos

```
activity4/
├── screens/
│   ├── activity4_intro_screen.dart    # Pantalla de introducción
│   └── activity4_game_screen.dart     # Pantalla del juego
└── README.md                          # Este archivo
```

## 🎮 Flujo del Juego

1. **Pantalla de Introducción** (`activity4_intro_screen.dart`)
   - Muestra instrucciones del juego
   - Botón "¡COMENZAR!" para iniciar

2. **Pantalla del Juego** (`activity4_game_screen.dart`)
   - Selecciona una imagen aleatoria de `activity3/images/`
   - Muestra el título: "✨ Elige las características correctas de:"
   - Muestra la imagen seleccionada
   - Muestra lista de características con checkboxes
   - Botón "✅ VERIFICAR RESPUESTA"

## 🖼️ Imágenes

Las imágenes se toman de: `lib/features/activities/activity3/images/`

Total de imágenes disponibles: **126 imágenes**

Categorías incluidas:
- Animales (león, tigre, elefante, jirafa, etc.)
- Accidentes geográficos (isla, montaña, volcán, etc.)
- Sistemas del cuerpo (digestivo, circulatorio, respiratorio, etc.)
- Higiene (lavándose manos, cepillándose, peinándose, etc.)
- Responsabilidades (cuidar mascota, regar plantas, sacar basura, etc.)
- Eventos (cumpleaños, navidad, etc.)
- Y más...

## 🔧 Implementación Actual

### ✅ Completado:
- [x] Pantalla de introducción con diseño infantil
- [x] Pantalla del juego con selección aleatoria de imágenes
- [x] Sistema de checkboxes para seleccionar características
- [x] Botón de verificar respuesta
- [x] Integración en el menú principal
- [x] Diseño responsive y atractivo para niños

### ⏳ Pendiente (TODOs):
- [ ] Integración con backend para obtener características reales
- [ ] Validación de respuestas con el modelo ML
- [ ] Sistema de puntuación
- [ ] Feedback visual (correcto/incorrecto)
- [ ] Animaciones de celebración
- [ ] Sonidos de feedback

## 🔌 Integración con Backend

### Endpoint a usar:
```
POST http://gateway-ip:8001/validar-caracteristicas
```

### Request:
```dart
// Archivo de imagen
File imageFile = File('path/to/image');

// Características seleccionadas
List<String> selectedCharacteristics = [
  "Animal salvaje",
  "Tiene melena",
  "Es carnívoro"
];

// Enviar al backend
FormData formData = FormData.fromMap({
  'image': await MultipartFile.fromFile(imageFile.path),
  'caracteristicas_seleccionadas': selectedCharacteristics.join(', '),
});
```

### Response esperada:
```json
{
  "es_correcto": true,
  "mensaje": "¡Perfecto! Todas las características son correctas 🎉",
  "nombre_objeto": "León",
  "caracteristicas_modelo": [
    "animal salvaje",
    "mamifero carnivoro",
    "melena en él macho"
  ],
  "caracteristicas_correctas": [
    "Animal salvaje",
    "Tiene melena",
    "Es carnívoro"
  ],
  "caracteristicas_incorrectas": [],
  "porcentaje_acierto": 100.0,
  "total_seleccionadas": 3,
  "total_correctas": 3,
  "esp32_signal_sent": true,
  "esp32_message": "b",
  "nextion_page_shown": "page2"
}
```

## 📝 Notas de Implementación

1. **Selección de Imagen**: 
   - Se selecciona aleatoriamente una imagen al iniciar el juego
   - La imagen se muestra con bordes redondeados y sombra

2. **Características Dummy**:
   - Actualmente usa características de ejemplo
   - Serán reemplazadas por las del backend

3. **Comparación Exacta**:
   - El backend usa comparación exacta (normalizada)
   - El frontend debe mostrar las opciones exactas del modelo

4. **Estado de Carga**:
   - Botón se deshabilita durante la validación
   - Muestra indicador de carga

## 🎨 Paleta de Colores

- **Primario**: `#AB47BC` (Morado claro)
- **Secundario**: `#8E24AA` (Morado oscuro)
- **Fondo**: `#FFF8E1` (Crema)
- **Texto**: `#424242` (Gris oscuro)
- **Blanco**: `#FFFFFF`

## 🚀 Próximos Pasos

1. Implementar llamada al backend
2. Parsear respuesta del backend
3. Mostrar feedback visual según resultado
4. Agregar animaciones de celebración
5. Implementar sistema de puntos
6. Agregar sonidos de feedback

## 📱 Screenshots

(Agregar screenshots cuando esté implementado)

---

**Creado**: 2026-01-08
**Última actualización**: 2026-01-08
