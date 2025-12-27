@echo off
REM start_ml_server.bat - Inicia el servidor ML

echo ========================================
echo   INICIANDO SERVIDOR ML (Puerto 8000)
echo ========================================
echo.

cd /d "%~dp0..\api"

echo Activando entorno virtual...
if exist .venv311\Scripts\activate.bat (
    call .venv311\Scripts\activate.bat
) else (
    echo [ERROR] No se encontro el entorno virtual .venv311
    echo Por favor, crea el entorno virtual primero
    pause
    exit /b 1
)

echo.
echo Iniciando servidor ML con BLIP...
echo.
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

pause
