# Script para agregar Go al PATH de Windows
# Requiere ejecutarse como Administrador

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  Configurar Go en PATH de Windows" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Verificar si se ejecuta como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] Este script requiere permisos de administrador" -ForegroundColor Yellow
    Write-Host "    Iniciando con privilegios elevados..." -ForegroundColor Yellow
    Write-Host ""
    
    # Reiniciar como administrador
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Rutas comunes de instalacion de Go
$goPaths = @(
    "C:\Program Files\Go\bin",
    "C:\Go\bin",
    "$env:ProgramFiles\Go\bin"
)

$goPath = $null
foreach ($path in $goPaths) {
    if (Test-Path $path) {
        $goPath = $path
        Write-Host "OK Go encontrado en: $path" -ForegroundColor Green
        break
    }
}

if (-not $goPath) {
    Write-Host "X Error: No se encontro instalacion de Go" -ForegroundColor Red
    Write-Host "  Rutas verificadas:" -ForegroundColor Yellow
    foreach ($path in $goPaths) {
        Write-Host "    - $path" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Instala Go primero desde: https://go.dev/dl/" -ForegroundColor Yellow
    pause
    exit 1
}

# Obtener PATH actual del sistema
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# Verificar si Go ya esta en el PATH
if ($machinePath -like "*$goPath*") {
    Write-Host "[i] Go ya esta en el PATH del sistema" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "[*] Agregando Go al PATH del sistema..." -ForegroundColor Cyan
    
    # Agregar Go al PATH del sistema (Machine)
    $newPath = "$machinePath;$goPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    
    Write-Host "OK Go agregado al PATH del sistema" -ForegroundColor Green
    Write-Host ""
}

# Configurar GOPATH si no existe
$goPathDir = "$env:USERPROFILE\go"
$currentGoPath = [Environment]::GetEnvironmentVariable("GOPATH", "User")

if (-not $currentGoPath) {
    Write-Host "[*] Configurando GOPATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("GOPATH", $goPathDir, "User")
    Write-Host "OK GOPATH configurado: $goPathDir" -ForegroundColor Green
    
    # Crear directorios de GOPATH
    New-Item -ItemType Directory -Path "$goPathDir\bin" -Force | Out-Null
    New-Item -ItemType Directory -Path "$goPathDir\src" -Force | Out-Null
    New-Item -ItemType Directory -Path "$goPathDir\pkg" -Force | Out-Null
    Write-Host "OK Directorios de GOPATH creados" -ForegroundColor Green
} else {
    Write-Host "[i] GOPATH ya configurado: $currentGoPath" -ForegroundColor Cyan
}

# Agregar GOPATH\bin al PATH del usuario
$goBinPath = "$goPathDir\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$goBinPath*") {
    Write-Host "[*] Agregando GOPATH\bin al PATH del usuario..." -ForegroundColor Cyan
    $newUserPath = "$userPath;$goBinPath"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "OK GOPATH\bin agregado al PATH" -ForegroundColor Green
} else {
    Write-Host "[i] GOPATH\bin ya esta en el PATH" -ForegroundColor Cyan
}

# Actualizar PATH en sesion actual
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "[OK] Configuracion completada!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Verificar instalacion
if (Get-Command go -ErrorAction SilentlyContinue) {
    $goVersion = go version
    Write-Host "Version de Go: $goVersion" -ForegroundColor Cyan
    Write-Host "GOPATH:        $goPathDir" -ForegroundColor Cyan
    Write-Host "Go binaries:   $goPath" -ForegroundColor Cyan
} else {
    Write-Host "[!] Go configurado pero aun no disponible" -ForegroundColor Yellow
    Write-Host "    Reinicia tu terminal o PC" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Cierra TODAS las ventanas de PowerShell/CMD" -ForegroundColor White
Write-Host "  2. Abre una nueva terminal" -ForegroundColor White
Write-Host "  3. Verifica con: go version" -ForegroundColor White
Write-Host ""

pause
