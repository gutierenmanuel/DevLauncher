# Script de desarrollo para Wails con Hot-Reload
# Autor: DevLauncher Project

$ErrorActionPreference = "Stop"

# Refrescar PATH de la sesion actual
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Banner
Write-Host "======================================" -ForegroundColor Magenta
Write-Host "   Wails Development Mode" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Verificar Go
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: Go no esta instalado" -ForegroundColor Red
    Write-Host "  Instala Go desde: https://go.dev/dl/" -ForegroundColor Yellow
    exit 1
}

$goVersion = (go version).Split(" ")[2]
Write-Host "OK Go $goVersion" -ForegroundColor Green

# Verificar Wails
if (-not (Get-Command wails -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: Wails no esta instalado" -ForegroundColor Red
    Write-Host "  Instala Wails con: go install github.com/wailsapp/wails/v2/cmd/wails@latest" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK Wails CLI instalado" -ForegroundColor Green
Write-Host ""

# Verificar pnpm
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: pnpm no esta instalado" -ForegroundColor Red
    Write-Host "  Instala pnpm con: npm install -g pnpm" -ForegroundColor Yellow
    exit 1
}

$pnpmVersion = pnpm --version
Write-Host "OK pnpm $pnpmVersion" -ForegroundColor Green
Write-Host ""

# Confirmar que usamos frontend directamente
Write-Host "OK Usando frontend directamente desde .\frontend\" -ForegroundColor Green
Write-Host "   (No es necesario copiar archivos)" -ForegroundColor Cyan
Write-Host ""

# Verificar dependencias del frontend
Write-Host "> Verificando dependencias del frontend..." -ForegroundColor Yellow
Push-Location frontend

if (-not (Test-Path "node_modules")) {
    Write-Host "  -> Instalando dependencias con pnpm..." -ForegroundColor Yellow
    pnpm install
} else {
    Write-Host "  OK Dependencias ya instaladas" -ForegroundColor Green
}

Pop-Location
Write-Host ""

# Cambiar al directorio de Wails
Push-Location wails-app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Iniciando Wails Dev Server..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Hot-Reload activado" -ForegroundColor Green
Write-Host "   Frontend: Vite, React, Tailwind" -ForegroundColor Yellow
Write-Host "   Backend:  Go, WSL Manager" -ForegroundColor Yellow
Write-Host "   Modo:     Directo (sin copia)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Magenta
Write-Host ""

# Ejecutar Wails en modo desarrollo
try {
    wails dev
} finally {
    Pop-Location
}
