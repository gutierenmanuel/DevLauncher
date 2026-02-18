# Script para instalar Node.js en Windows usando nvm-windows

param(
    [string]$Version = "20"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  Instalando Node.js v$Version" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Verificar si Node.js ya esta instalado
if (Get-Command node -ErrorAction SilentlyContinue) {
    $currentVersion = node --version
    Write-Host "[i] Node.js ya esta instalado: $currentVersion" -ForegroundColor Cyan
    Write-Host ""
}

# Verificar si nvm-windows esta instalado
$nvmPath = "$env:APPDATA\nvm"
$nvmExe = "$nvmPath\nvm.exe"

if (Test-Path $nvmExe) {
    Write-Host "OK nvm-windows ya esta instalado" -ForegroundColor Green
} else {
    Write-Host "[*] nvm-windows no esta instalado" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para instalar Node.js necesitas nvm-windows:" -ForegroundColor Cyan
    Write-Host "  1. Descarga desde: https://github.com/coreybutler/nvm-windows/releases" -ForegroundColor White
    Write-Host "  2. Instala nvm-setup.exe" -ForegroundColor White
    Write-Host "  3. Vuelve a ejecutar este script" -ForegroundColor White
    Write-Host ""
    Write-Host "O usa winget:" -ForegroundColor Cyan
    Write-Host "  winget install CoreyButler.NVMforWindows" -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host "Deseas instalar con winget ahora? (s/n)"
    if ($response -eq "s") {
        Write-Host "[*] Instalando nvm-windows con winget..." -ForegroundColor Cyan
        winget install CoreyButler.NVMforWindows
        Write-Host "OK Instalado. Reinicia tu terminal y ejecuta este script de nuevo" -ForegroundColor Green
        exit 0
    } else {
        exit 1
    }
}

# Instalar Node.js con nvm
Write-Host ""
Write-Host "[*] Instalando Node.js v$Version con nvm..." -ForegroundColor Cyan
& nvm install $Version
& nvm use $Version

# Verificar instalacion
Write-Host ""
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    $npmVersion = npm --version
    
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "[OK] Node.js instalado correctamente!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Node.js: $nodeVersion" -ForegroundColor Cyan
    Write-Host "npm:     v$npmVersion" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Comandos utiles de nvm:" -ForegroundColor Yellow
    Write-Host "  nvm list              - Listar versiones instaladas" -ForegroundColor White
    Write-Host "  nvm install <version> - Instalar version" -ForegroundColor White
    Write-Host "  nvm use <version>     - Usar version" -ForegroundColor White
    Write-Host "  nvm current           - Ver version actual" -ForegroundColor White
} else {
    Write-Host "X Error: Node.js no se instalo correctamente" -ForegroundColor Red
    Write-Host "  Reinicia tu terminal e intenta de nuevo" -ForegroundColor Yellow
}
Write-Host ""
