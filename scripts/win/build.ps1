# DevLauncher Build System para Windows
# Compilacion completa de Frontend mas Wails

$ErrorActionPreference = "Stop"

# Refrescar PATH de la sesion actual
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Banner
Write-Host "======================================" -ForegroundColor Magenta
Write-Host "   DevLauncher Build System" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Verificar Go
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: Go no esta instalado" -ForegroundColor Red
    exit 1
}

$goVersion = (go version).Split(" ")[2]
Write-Host "OK Go $goVersion" -ForegroundColor Green

# Verificar Wails
if (-not (Get-Command wails -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: Wails no esta instalado" -ForegroundColor Red
    Write-Host "  Instala con: go install github.com/wailsapp/wails/v2/cmd/wails@latest" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK Wails CLI instalado" -ForegroundColor Green

# Verificar pnpm
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: pnpm no esta instalado" -ForegroundColor Red
    Write-Host "  Instala con: npm install -g pnpm" -ForegroundColor Yellow
    exit 1
}

$pnpmVersion = pnpm --version
Write-Host "OK pnpm $pnpmVersion" -ForegroundColor Green
Write-Host ""

# Crear directorio de salida
$OUTPUT_DIR = ".\bin"
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Construyendo Aplicacion Wails" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# Limpiar builds anteriores
Write-Host "[*] Limpiando..." -ForegroundColor Yellow
if (Test-Path "wails-app\build") { Remove-Item -Recurse -Force "wails-app\build" }
if (Test-Path "wails-app\frontend") { Remove-Item -Recurse -Force "wails-app\frontend" }
if (Test-Path "frontend\dist") { Remove-Item -Recurse -Force "frontend\dist" }

# Instalar y compilar frontend
Write-Host "[*] Instalando dependencias del frontend..." -ForegroundColor Cyan
Push-Location frontend
pnpm install

Write-Host "[*] Compilando frontend..." -ForegroundColor Cyan
pnpm build

if (-not (Test-Path "dist\index.html")) {
    Write-Host "X Error: Frontend no compilado" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "OK Frontend compilado" -ForegroundColor Green
Pop-Location

# Copiar frontend a wails-app
Write-Host "[*] Copiando frontend a wails-app..." -ForegroundColor Cyan
if (-not (Test-Path "wails-app\frontend")) {
    New-Item -ItemType Directory -Path "wails-app\frontend" -Force | Out-Null
}
Copy-Item -Recurse -Force "frontend\dist" "wails-app\frontend\"

if (-not (Test-Path "wails-app\frontend\dist\index.html")) {
    Write-Host "X Error: No se copio correctamente" -ForegroundColor Red
    exit 1
}

Write-Host "OK Frontend copiado a wails-app/frontend/dist" -ForegroundColor Green

# Compilar Wails
Push-Location wails-app

Write-Host ""
Write-Host "[*] Construyendo para Windows (DEBUG con consola)..." -ForegroundColor Cyan
wails build -platform windows/amd64 -debug -o devlauncher-debug.exe

if (Test-Path "build\bin\devlauncher-debug.exe") {
    Copy-Item "build\bin\devlauncher-debug.exe" "..\$OUTPUT_DIR\devlauncher-windows-debug.exe"
    Write-Host "[OK] Debug build completo!" -ForegroundColor Green
} else {
    Write-Host "X Error en build" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""
Write-Host "[*] Construyendo para Windows (PRODUCCION sin consola)..." -ForegroundColor Cyan
wails build -platform windows/amd64 -ldflags "-H windowsgui" -o devlauncher.exe

if (Test-Path "build\bin\devlauncher.exe") {
    Copy-Item "build\bin\devlauncher.exe" "..\$OUTPUT_DIR\devlauncher-windows.exe"
    Write-Host "[OK] Production build completo!" -ForegroundColor Green
}

Pop-Location

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "[*] Build completado!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Get-ChildItem $OUTPUT_DIR | Format-Table Name, Length, LastWriteTime -AutoSize

Write-Host ""
Write-Host "[*] Ejecutables disponibles en: $OUTPUT_DIR" -ForegroundColor Yellow
Write-Host ""
