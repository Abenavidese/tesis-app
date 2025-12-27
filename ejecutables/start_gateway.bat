@echo off
REM start_gateway.bat - Inicia el API Gateway

echo ========================================
echo   INICIANDO API GATEWAY (Puerto 8001)
echo ========================================
echo.

cd /d "%~dp0..\gateway"

echo Activando entorno virtual...
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
) else if exist ..\api\.venv311\Scripts\activate.bat (
    call ..\api\.venv311\Scripts\activate.bat
) else (
    echo [ADVERTENCIA] No se encontro entorno virtual
    echo Continuando con Python del sistema...
)

echo.
echo Iniciando API Gateway...
echo.
python gateway.py

pause
