@echo off
:: --- Verifica se é admin ---
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo Pedindo permissao de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- Abre PowerShell em nova janela, UTF-8, menu interativo ---
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0.ps1"
exit

exit

