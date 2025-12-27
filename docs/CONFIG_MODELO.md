# 📝 Configuración del Modelo BLIP

## 🔧 Archivo .env

El proyecto usa variables de entorno para configurar la ruta del modelo BLIP. Esto permite cambiar fácilmente la ubicación del modelo sin modificar el código.

## 📁 Estructura

```
api/
├── .env                    # ← Archivo de configuración (editalo aquí)
├── main.py
└── blip/
    └── generation.py       # ← Lee la ruta desde .env
```

## ⚙️ Configuración

### Archivo `.env`

```env
# Ruta al modelo BLIP entrenado
BLIP_MODEL_PATH=C:\Users\EleXc\Downloads\bliputf-esp-last2-20251224T072956Z-3-001\bliputf-esp-last2

# Configuración del servidor
HOST=0.0.0.0
PORT=8000
```

### Cambiar la Ruta del Modelo

1. Abre `api/.env`
2. Modifica `BLIP_MODEL_PATH` con la nueva ruta:
   ```env
   BLIP_MODEL_PATH=C:\ruta\a\tu\modelo
   ```
3. Reinicia el servidor

## 🚀 Uso

El sistema cargará automáticamente la ruta desde `.env`:

```python
from blip.generation import BlipEspanol

# Carga automáticamente desde BLIP_MODEL_PATH
modelo = BlipEspanol.from_pretrained()

# O especifica una ruta manualmente
modelo = BlipEspanol.from_pretrained(model_path="C:\\otra\\ruta")
```

## 📋 Modelos Disponibles

### Modelo Actual (Recomendado)
- **Carpeta**: `bliputf-esp-last2`
- **Ubicación**: Ver `.env`
- **Características**: 
  - Entrenado con 44 categorías
  - Español optimizado
  - Cuantización INT8

### Cambiar de Modelo

Si entrenas un nuevo modelo:

1. Guarda el modelo en una carpeta
2. Actualiza `.env`:
   ```env
   BLIP_MODEL_PATH=C:\ruta\al\nuevo\modelo
   ```
3. Reinicia el servidor

## 🔍 Verificación

Para verificar qué modelo está cargado:

```bash
# En el log del servidor verás:
⏳ Cargando modelo BLIP desde C:\Users\...\bliputf-esp-last2...
✅ Modelo BLIP cargado y optimizado
```

## ⚠️ Troubleshooting

### Error: "No such file or directory"

**Causa**: La ruta en `.env` no existe o está mal escrita

**Solución**: 
1. Verifica que la carpeta existe
2. Usa rutas absolutas completas
3. En Windows, puedes usar `\` o `/` en las rutas

### Error: "is not a local folder"

**Causa**: El modelo no está en la ubicación especificada

**Solución**:
1. Verifica que el modelo esté descargado
2. Actualiza `BLIP_MODEL_PATH` en `.env`
3. Asegúrate que la carpeta contiene:
   - `config.json`
   - `model.safetensors`
   - `preprocessor_config.json`
   - `tokenizer.json`

## 📝 Ejemplo Completo

```env
# .env
BLIP_MODEL_PATH=C:\Users\EleXc\Desktop\tesis_app\api\blip-final-5
HOST=0.0.0.0
PORT=8000
```

```python
# main.py o tu script
from blip.generation import quick_generate
from PIL import Image

# El modelo se carga automáticamente desde .env
imagen = Image.open("foto.jpg")
caption = quick_generate(imagen)
print(caption)  # "Un niño pequeño jugando en el jardín"
```

## 🔐 Seguridad

⚠️ **Importante**: 
- No subas `.env` a Git (ya está en `.gitignore`)
- Cada desarrollador debe tener su propio `.env`
- Usa rutas locales, no compartas rutas absolutas

---

**✅ Configuración centralizada. Cambia la ruta del modelo editando solo `.env`**
