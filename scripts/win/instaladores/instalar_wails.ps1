# Script para instalar Wails en Windows

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  Instalando Wails" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

# Verificar si Go esta instalado
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "X Error: Go no esta instalado" -ForegroundColor Red
    Write-Host "  Instala Go primero con:" -ForegroundColor Yellow
    Write-Host "  .\scripts\win\instaladores\instalar_go.ps1" -ForegroundColor White
    exit 1
}

$goVersion = go version
Write-Host "OK Go detectado: $goVersion" -ForegroundColor Green
Write-Host ""

# Verificar dependencias de Windows
Write-Host "[*] Verificando dependencias de Windows..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Wails en Windows requiere:" -ForegroundColor Yellow
Write-Host "  1. WebView2 Runtime (generalmente ya instalado)" -ForegroundColor White
Write-Host "  2. Build Tools (opcional para builds avanzados)" -ForegroundColor White
Write-Host ""

# Verificar WebView2
$webview2Paths = @(
    "$env:ProgramFiles (x86)\Microsoft\EdgeWebView\Application",
    "$env:ProgramFiles\Microsoft\EdgeWebView\Application"
)

$webview2Installed = $false
foreach ($path in $webview2Paths) {
    if (Test-Path $path) {
        $webview2Installed = $true
        Write-Host "OK WebView2 Runtime encontrado" -ForegroundColor Green
        break
    }
}

if (-not $webview2Installed) {
    Write-Host "[!] WebView2 Runtime no encontrado" -ForegroundColor Yellow
    Write-Host "    Descargalo desde:" -ForegroundColor Yellow
    Write-Host "    https://go.microsoft.com/fwlink/p/?LinkId=2124703" -ForegroundColor White
    Write-Host ""
    $response = Read-Host "Continuar sin WebView2? (s/n)"
    if ($response -ne "s") {
        exit 1
    }
}

# Instalar Wails CLI
Write-Host ""
Write-Host "[*] Instalando Wails CLI..." -ForegroundColor Cyan
go install github.com/wailsapp/wails/v2/cmd/wails@latest

# Verificar que GOPATH/bin este en PATH
$goPath = if ($env:GOPATH) { $env:GOPATH } else { "$env:USERPROFILE\go" }
$goBin = "$goPath\bin"

if ($env:Path -notlike "*$goBin*") {
    Write-Host ""
    Write-Host "[!] Agregando $goBin al PATH..." -ForegroundColor Yellow
    
    # Agregar al PATH del usuario
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$goBin*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$currentPath;$goBin",
            "User"
        )
    }
    
    # Actualizar PATH en sesion actual
    $env:Path += ";$goBin"
    Write-Host "OK PATH actualizado" -ForegroundColor Green
}

# Verificar instalacion
Write-Host ""
if (Get-Command wails -ErrorAction SilentlyContinue) {
    $wailsVersion = wails version
    
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "[OK] Wails instalado correctamente!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "$wailsVersion" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Comandos basicos de Wails:" -ForegroundColor Yellow
    Write-Host "  wails init -n myapp -t vanilla - Crear proyecto" -ForegroundColor White
    Write-Host "  wails dev                      - Modo desarrollo" -ForegroundColor White
    Write-Host "  wails build                    - Build produccion" -ForegroundColor White
    Write-Host "  wails doctor                   - Verificar instalacion" -ForegroundColor White
    Write-Host ""
    Write-Host "Templates disponibles:" -ForegroundColor Yellow
    Write-Host "  vanilla, vue, react, svelte, lit, angular" -ForegroundColor White
    Write-Host ""
    Write-Host "Mas info: https://wails.io/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[*] Ejecutando wails doctor..." -ForegroundColor Cyan
    wails doctor
} else {
    Write-Host "X Error: Wails instalado pero no esta en PATH" -ForegroundColor Red
    Write-Host "  Reinicia tu terminal o PC" -ForegroundColor Yellow
}
Write-Host ""
