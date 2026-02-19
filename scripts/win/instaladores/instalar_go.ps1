# Script para instalar Go en Windows
# Descarga e instala Go automaticamente

param(
    [string]$Version = "1.22.10"
)

$ErrorActionPreference = "Stop"

# Auto-elevar a administrador si no se tienen los permisos necesarios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Se requieren permisos de administrador para instalar Go." -ForegroundColor Yellow
    Write-Host "Solicitando elevacion..." -ForegroundColor Yellow
    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process $psExe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Version $Version" -Verb RunAs -Wait
    exit
}

Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  Instalando Go $Version en Windows" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Detectar arquitectura
$arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
$goFile = "go$Version.windows-$arch.msi"
$downloadUrl = "https://go.dev/dl/$goFile"
$installerPath = "$env:TEMP\$goFile"

# Verificar si Go ya esta instalado
if (Get-Command go -ErrorAction SilentlyContinue) {
    $currentVersion = (go version).Split(" ")[2]
    Write-Host "[!] Go ya esta instalado: $currentVersion" -ForegroundColor Yellow
    $response = Read-Host "Deseas reinstalar? (s/n)"
    if ($response -ne "s") {
        Write-Host "Instalacion cancelada" -ForegroundColor Yellow
        exit 0
    }
}

# Descargar instalador
Write-Host "[*] Descargando Go $Version..." -ForegroundColor Cyan
Write-Host "    URL: $downloadUrl" -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "OK Descarga completa" -ForegroundColor Green
} catch {
    Write-Host "X Error al descargar Go" -ForegroundColor Red
    Write-Host "  Verifica la version en: https://go.dev/dl/" -ForegroundColor Yellow
    exit 1
}

# Instalar
Write-Host ""
Write-Host "[*] Instalando Go..." -ForegroundColor Cyan
Write-Host "    (Aparecera una ventana de progreso)" -ForegroundColor Gray

$logFile = "$env:TEMP\go-install.log"
$proc = Start-Process msiexec.exe `
    -ArgumentList "/i `"$installerPath`" /passive /norestart /log `"$logFile`"" `
    -Wait -PassThru

if ($proc.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "X Error en la instalacion (codigo: $($proc.ExitCode))" -ForegroundColor Red
    if (Test-Path $logFile) {
        Write-Host "  Ultimas lineas del log:" -ForegroundColor Yellow
        Get-Content $logFile | Select-Object -Last 15 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    exit 1
}
Write-Host "OK Instalacion completada" -ForegroundColor Green

# Limpiar
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
Remove-Item $logFile -Force -ErrorAction SilentlyContinue

# Refrescar PATH en sesion actual
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Verificar instalacion
Write-Host ""
if (Get-Command go -ErrorAction SilentlyContinue) {
    $installedVersion = go version
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "[OK] Go instalado correctamente!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Version: $installedVersion" -ForegroundColor Cyan
    Write-Host "GOPATH:  $env:USERPROFILE\go" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Yellow
    Write-Host "  1. Reinicia tu terminal/PowerShell" -ForegroundColor White
    Write-Host "  2. Verifica con: go version" -ForegroundColor White
    Write-Host "  3. Tu workspace Go esta en: $env:USERPROFILE\go" -ForegroundColor White
} else {
    Write-Host "[!] Go instalado pero no esta en PATH" -ForegroundColor Yellow
    Write-Host "    Reinicia tu terminal o PC" -ForegroundColor Yellow
}
Write-Host ""
