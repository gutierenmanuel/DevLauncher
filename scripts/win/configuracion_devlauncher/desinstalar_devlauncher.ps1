# Script: Desinstalar DevLauncher en Windows
# Ejecuta el uninstaller instalado en el directorio de DevLauncher.

$ErrorActionPreference = "Stop"

$installDir = Join-Path $HOME ".devscripts"
$uninstaller = Join-Path $installDir "uninstaller.exe"

if (-not (Test-Path $uninstaller)) {
    Write-Host "No se encontró el uninstaller instalado en: $uninstaller"
    Write-Host "Instala DevLauncher para generar el desinstalador local."
    exit 1
}

Write-Host "Se ejecutará: $uninstaller"
$confirm = Read-Host "¿Continuar desinstalación? (s/N)"

if ($confirm -notmatch '^[sS]$') {
    Write-Host "Desinstalación cancelada."
    exit 0
}

Start-Process -FilePath $uninstaller -Wait
