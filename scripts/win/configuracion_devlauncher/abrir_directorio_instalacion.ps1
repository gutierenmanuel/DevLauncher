# Script: Abrir carpeta de instalación de DevLauncher
# Abre explorer.exe en el directorio donde está instalado el ejecutable devlauncher.

$ErrorActionPreference = "Stop"

$targetDir = $null

$cmd = Get-Command devlauncher -ErrorAction SilentlyContinue
if ($cmd -and $cmd.CommandType -eq "Application" -and (Test-Path $cmd.Path)) {
    $targetDir = Split-Path -Parent $cmd.Path
}

if (-not $targetDir) {
    $rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
    $targetDir = $rootDir.Path
}

Write-Host "Abriendo explorer en: $targetDir"
Start-Process explorer.exe $targetDir
Read-Host "Pulsa Enter para continuar"
