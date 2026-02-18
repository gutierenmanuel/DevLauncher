@echo off
echo ========================================
echo  Instalando PowerShell 7
echo ========================================
echo.

winget install --id Microsoft.PowerShell --source winget

echo.
echo ========================================
echo PowerShell 7 instalado!
echo ========================================
echo.
echo Cierra esta ventana y abre una nueva PowerShell
echo Ejecuta: pwsh --version
echo.
pause
