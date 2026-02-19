# Script: Mostrar versión actual de DevLauncher
# Muestra la versión instalada leyendo VERSION.txt.

$ErrorActionPreference = "Stop"

$installDir = Join-Path $HOME ".devscripts"
$versionFile = Join-Path $installDir "VERSION.txt"

if (-not (Test-Path $versionFile)) {
    Write-Host "No se encontró VERSION.txt en: $installDir"
    exit 1
}

$line = Get-Content $versionFile | Select-Object -First 1
$token = ($line -split '\s+')[0]

if (-not $token) {
    Write-Host "No se pudo leer la versión."
    exit 1
}

Write-Host "Versión actual: $token"
