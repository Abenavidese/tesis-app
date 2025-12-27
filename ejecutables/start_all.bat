@echo off
REM start_all.bat - Inicia todo el sistema (ML Server + Gateway)

echo ========================================
echo   INICIANDO SISTEMA COMPLETO
echo ========================================
echo.
echo Este script abrira 2 ventanas:
echo   1. Servidor ML (Puerto 8000)
echo   2. API Gateway (Puerto 8001)
echo.
echo Presiona cualquier tecla para continuar...
pause > nul

cd /d "%~dp0"

echo.
echo Iniciando Servidor ML...
start "Servidor ML - Puerto 8000" cmd /k "%~dp0start_ml_server.bat"

timeout /t 3 > nul

echo Iniciando API Gateway...
start "API Gateway - Puerto 8001" cmd /k "%~dp0start_gateway.bat"

echo.
echo ========================================
echo   SISTEMA INICIADO
echo ========================================
echo.
echo Servidor ML:    http://localhost:8000
echo API Gateway:    http://localhost:8001
echo.
echo Puedes cerrar esta ventana.
echo Las otras 2 ventanas deben permanecer abiertas.
echo.
pause
