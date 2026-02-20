# Script: Desinstalar DevLauncher en Windows
# Ejecuta el uninstaller.exe instalado en el directorio de DevLauncher.

$ErrorActionPreference = "Stop"

$installDir = Join-Path $HOME ".devlauncher"
$uninstaller = Join-Path $installDir "uninstaller.exe"

if (-not (Test-Path $uninstaller)) {
    Write-Host "No se encontró el uninstaller instalado en: $uninstaller" -ForegroundColor Red
    Write-Host "Instala DevLauncher primero para generar el desinstalador."
    exit 1
}

Write-Host "Iniciando desinstalador interactivo..." -ForegroundColor Cyan
Write-Host ""

# Ejecutar el uninstaller.exe directamente en la terminal actual
& $uninstaller

Write-Host ""
Write-Host "Vuelve pronto!" -ForegroundColor Yellow
exit 0
