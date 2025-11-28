# 📱 Tesis App - Aplicación Flutter con IA

Una aplicación Flutter moderna que utiliza inteligencia artificial para generar descripciones automáticas de imágenes usando el modelo BLIP.

## ✨ Funcionalidades

### 📸 **Captura de Imágenes**
- **Tomar Foto**: Captura imágenes directamente con la cámara del dispositivo
- **Cargar Imagen**: Selecciona imágenes existentes desde la galería del dispositivo
- Optimización automática de calidad y tamaño de imagen

### 🤖 **Análisis con IA**
- Generación automática de descripciones usando modelo BLIP
- Procesamiento local del servidor API
- Descripción en lenguaje natural de los contenidos de la imagen

### 💾 **Gestión de Archivos**
- Guardado automático de imágenes procesadas
- Limpieza automática de archivos antiguos
- Vista previa de la última imagen analizada

### 🎨 **Interfaz Usuario**
- Tema oscuro moderno con colores personalizados
- Animaciones fluidas y transiciones suaves
- Indicadores de progreso durante el procesamiento
- Manejo elegante de errores con opciones de reintento

## 🏗️ Arquitectura

**Patrón de Arquitectura por Capas:**
- **Core Layer**: Servicios base y configuraciones
- **Feature Layer**: Funcionalidades específicas organizadas por módulos
- **Shared Layer**: Componentes reutilizables
- **Theme Layer**: Diseño consistente

**Servicios Principales:**
- **ApiService**: Comunicación con el servidor BLIP
- **CameraService**: Manejo de cámara y galería
- **FileService**: Gestión y limpieza de archivos
- **Provider Pattern**: Manejo de estado reactivo

## 🚀 Tecnologías

**Frontend (Flutter):**
- Flutter SDK 3.10.0+
- Material Design 3
- Image Picker para captura/selección
- HTTP para comunicación API

**Backend (Python):**
- FastAPI para API REST
- Modelo BLIP para generación de captions
- Transformers 4.53.2

## ✅ Estado Actual

**Funcionalidades Implementadas:**
- ✅ Captura de fotos con cámara
- ✅ Carga de imágenes desde galería  
- ✅ Comunicación con API BLIP
- ✅ Interfaz de usuario completa
- ✅ Manejo de errores robusto
- ✅ Arquitectura modular y escalable

**Listo para:**
- 🎨 Personalización de diseño
- 🔧 Nuevas funcionalidades
- 📱 Mejoras de UI/UX
