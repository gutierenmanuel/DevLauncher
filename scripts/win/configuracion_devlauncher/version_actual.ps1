# Script: Mostrar versión actual de DevLauncher
# Muestra la versión instalada leyendo VERSION.txt.

$ErrorActionPreference = "Stop"

function Pause-And-Exit([int]$Code = 0) {
    Read-Host "Pulsa Enter para continuar"
    exit $Code
}

$installDir = Join-Path $HOME ".devlauncher"
$versionFile = Join-Path $installDir "VERSION.txt"

if (-not (Test-Path $versionFile)) {
    Write-Host "No se encontró VERSION.txt en: $installDir"
    Pause-And-Exit 1
}

$line = Get-Content $versionFile | Select-Object -First 1
$token = ($line -split '\s+')[0]

if (-not $token) {
    Write-Host "No se pudo leer la versión."
    Pause-And-Exit 1
}

Write-Host "Versión actual: $token"
Pause-And-Exit 0
