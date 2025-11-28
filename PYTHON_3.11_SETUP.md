# 🐍 Guía para Usar Python 3.11.9 Correctamente

## 🔍 Problema Identificado
Tu entorno virtual `.venv311` está usando Python 3.14.0 en lugar de Python 3.11.9

## ✅ Solución (Ejecutar en PowerShell)

### **1. Crear Entorno Virtual con Python 3.11:**
```powershell
# Usar Python Launcher para especificar versión 3.11
py -3.11 -m venv .venv311

# O alternativamente:
python3.11 -m venv .venv311
```

### **2. Activar el Entorno:**
```powershell
.\.venv311\Scripts\Activate.ps1
```

### **3. Verificar la Versión:**
```powershell
python --version
# Debería mostrar: Python 3.11.x
```

### **4. Instalar Dependencias:**
```powershell
pip install fastapi uvicorn pillow torch transformers
```

### **5. Ejecutar FastAPI:**
```powershell
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

## 🚀 Comandos Completos (Copia y Pega)

### **Recrear Entorno desde Cero:**
```powershell
# Si existe, eliminar el entorno actual
Remove-Item -Recurse -Force .venv311 -ErrorAction SilentlyContinue

# Crear nuevo entorno con Python 3.11
py -3.11 -m venv .venv311

# Activar entorno
.\.venv311\Scripts\Activate.ps1

# Verificar versión
python --version

# Instalar dependencias
pip install fastapi uvicorn pillow torch transformers

# Ejecutar servidor
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

## 📝 Notas Importantes

- **`py -3.11`** fuerza el uso de Python 3.11 específicamente
- **`.venv311`** es el nombre del entorno virtual
- **PowerShell** requiere `.Scripts\Activate.ps1` para activar
- **Transformers 4.53.2** funciona mejor con Python 3.11.9

## 🔧 Si Hay Problemas

### **Error de Ejecución de Scripts:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Verificar Versiones Disponibles:**
```powershell
py -0
```

### **Usar Ruta Completa si es Necesario:**
```powershell
C:\Python311\python.exe -m venv .venv311
```