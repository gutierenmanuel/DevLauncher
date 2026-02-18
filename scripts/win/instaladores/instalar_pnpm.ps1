# Script para instalar pnpm en Windows

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  Instalando pnpm" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Verificar si Node.js esta instalado
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: Node.js no esta instalado" -ForegroundColor Red
    Write-Host "  Instala Node.js primero con:" -ForegroundColor Yellow
    Write-Host "  .\scripts\win\instaladores\instalar_nodejs.ps1" -ForegroundColor White
    exit 1
}

$nodeVersion = node --version
Write-Host "OK Node.js detectado: $nodeVersion" -ForegroundColor Green
Write-Host ""

# Verificar si pnpm ya esta instalado
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $currentVersion = pnpm --version
    Write-Host "[!] pnpm ya esta instalado: v$currentVersion" -ForegroundColor Yellow
    Write-Host "    Actualizando..." -ForegroundColor Yellow
}

# Instalar pnpm globalmente con npm
Write-Host "[*] Instalando pnpm globalmente..." -ForegroundColor Cyan
npm install -g pnpm

# Verificar instalacion
Write-Host ""
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $pnpmVersion = pnpm --version
    
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "[OK] pnpm instalado correctamente!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Version: v$pnpmVersion" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Comandos basicos de pnpm:" -ForegroundColor Yellow
    Write-Host "  pnpm install          - Instalar dependencias" -ForegroundColor White
    Write-Host "  pnpm add <paquete>    - Agregar paquete" -ForegroundColor White
    Write-Host "  pnpm remove <paquete> - Remover paquete" -ForegroundColor White
    Write-Host "  pnpm run <script>     - Ejecutar script" -ForegroundColor White
    Write-Host "  pnpm update           - Actualizar dependencias" -ForegroundColor White
    Write-Host ""
    Write-Host "Mas info: https://pnpm.io/" -ForegroundColor Gray
} else {
    Write-Host "X Error: pnpm no se instalo correctamente" -ForegroundColor Red
    Write-Host "  Reinicia tu terminal e intenta de nuevo" -ForegroundColor Yellow
}
Write-Host ""
