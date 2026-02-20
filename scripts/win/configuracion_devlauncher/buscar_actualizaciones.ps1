# Script: Buscar actualizaciones de DevLauncher (modo local)
# Muestra versión actual y binarios disponibles sin consultar internet.

$ErrorActionPreference = "Stop"

function Pause-And-Exit([int]$Code = 0) {
    Read-Host "Pulsa Enter para continuar"
    exit $Code
}

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$versionFile = Join-Path $rootDir "VERSION.txt"
$outputsDir = Join-Path $rootDir "outputs"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║      Buscar actualizaciones (modo local / offline)        ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""

if (Test-Path $versionFile) {
    $version = Get-Content $versionFile | Select-Object -First 1
    Write-Host "Versión local: $version"
} else {
    Write-Host "No se encontró VERSION.txt en: $rootDir"
}

Write-Host ""
Write-Host "Binarios en outputs/:"
if (Test-Path $outputsDir) {
    Get-ChildItem $outputsDir -File | Sort-Object Name | ForEach-Object {
        Write-Host " - $($_.Name)"
    }
} else {
    Write-Host " - No existe carpeta outputs"
}

Write-Host ""
Write-Host "Estado: comprobación online desactivada por ahora."
Pause-And-Exit 0
