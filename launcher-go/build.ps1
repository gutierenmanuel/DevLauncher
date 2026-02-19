# Script de compilación del launcher para Windows
# Compila el launcher para Windows, Linux y macOS

param(
    [switch]$All,       # Compilar para todas las plataformas
    [switch]$Windows,   # Solo Windows
    [switch]$Linux,     # Solo Linux
    [switch]$Mac        # Solo macOS
)

$Green  = "`e[32m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan   = "`e[36m"
$Gray   = "`e[90m"
$Red    = "`e[31m"
$NC     = "`e[0m"

# Si no se pasa ningún flag, compilar solo para Windows (plataforma actual)
if (-not $All -and -not $Windows -and -not $Linux -and -not $Mac) {
    $Windows = $true
}

$LauncherDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot    = Split-Path -Parent $LauncherDir
$OutputDir   = Join-Path $RepoRoot "outputs"
$IconPath    = Join-Path $RepoRoot "static\devL.ico"
$SysoPath    = Join-Path $LauncherDir "rsrc_windows_amd64.syso"
$VersionFile = Join-Path $RepoRoot "VERSION.txt"

if (-not (Test-Path $VersionFile)) {
    throw "No se encontró VERSION.txt"
}

$VersionToken = ((Get-Content -Path $VersionFile -TotalCount 1).Trim() -split '\s+')[0]
$VersionNumber = $VersionToken.TrimStart('v','V')
if ([string]::IsNullOrWhiteSpace($VersionNumber)) {
    throw "No se pudo leer la versión numérica desde VERSION.txt"
}

$LauncherWinName   = "$VersionNumber-devlauncher.exe"
$LauncherLinuxName = "$VersionNumber-devlauncher-linux"
$LauncherMacName   = "$VersionNumber-devlauncher-mac"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║  Build Launcher 🏗️                                         ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Verificar que Go está instalado
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "  ${Red}✗${NC} Go no está instalado o no está en el PATH"
    Write-Host "  ${Yellow}ℹ${NC} Descárgalo en: https://go.dev/dl/"
    exit 1
}

$goVersion = go version
Write-Host "  ${Green}✓${NC} Go detectado: ${Cyan}$goVersion${NC}"
Write-Host "  ${Green}✓${NC} Carpeta de salida: ${Cyan}$OutputDir${NC}"
Write-Host "  ${Green}✓${NC} Versión detectada: ${Cyan}$VersionNumber${NC}"
Write-Host ""

# Entrar al directorio del launcher
Set-Location $LauncherDir

# Descargar dependencias si hace falta
Write-Host "  ${Cyan}⏳${NC} Verificando dependencias..."
go mod tidy 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ${Yellow}⚠${NC} go mod tidy tuvo advertencias (puede ser normal)"
} else {
    Write-Host "  ${Green}✓${NC} Dependencias OK"
}
Write-Host ""

$buildErrors = 0

function New-WindowsIconResource {
    if (-not (Test-Path $IconPath)) {
        Write-Host "  ${Yellow}⚠${NC} Icono no encontrado: $IconPath"
        return
    }

    Write-Host "  ${Cyan}⏳${NC} Generando recurso de icono para Windows..."
    & go run github.com/akavel/rsrc@latest -ico $IconPath -o $SysoPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo generar el recurso de icono Windows"
    }
    Write-Host "  ${Green}✓${NC} Icono Windows aplicado"
}

function Build-Target {
    param($OS, $Arch, $Output, $Label)

    Write-Host "  ${Cyan}⏳${NC} Compilando para $Label..."

    $env:GOOS   = $OS
    $env:GOARCH = $Arch

    $outPath = Join-Path $OutputDir $Output
    go build -ldflags="-s -w" -o $outPath 2>&1

    if ($LASTEXITCODE -eq 0) {
        $size = [math]::Round((Get-Item $outPath).Length / 1MB, 2)
        Write-Host "  ${Green}✓${NC} $Output creado ${Gray}($size MB)${NC}"
    } else {
        Write-Host "  ${Red}✗${NC} Error al compilar para $Label"
        $script:buildErrors++
    }

    # Limpiar variables de entorno
    Remove-Item Env:GOOS   -ErrorAction SilentlyContinue
    Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
}

# Compilar según flags
if ($Windows -or $All) {
    New-WindowsIconResource
    Build-Target -OS "windows" -Arch "amd64" -Output $LauncherWinName   -Label "Windows (amd64)"
}

if ($Linux -or $All) {
    Build-Target -OS "linux"   -Arch "amd64" -Output $LauncherLinuxName  -Label "Linux (amd64)"
}

if ($Mac -or $All) {
    Build-Target -OS "darwin"  -Arch "amd64" -Output $LauncherMacName    -Label "macOS (amd64)"
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

if ($buildErrors -eq 0) {
    Write-Host ""
    Write-Host "  ${Green}✓ Build completado correctamente${NC}"
    Write-Host ""
    Write-Host "  ${Cyan}Binarios disponibles:${NC}"
    @($LauncherWinName, $LauncherLinuxName, $LauncherMacName) | ForEach-Object {
        $p = Join-Path $OutputDir $_
        if (Test-Path $p) {
            $size = [math]::Round((Get-Item $p).Length / 1MB, 2)
            Write-Host "    ${Green}$_${NC}  ${Gray}$size MB${NC}"
        }
    }
    Write-Host ""
    Write-Host "  ${Cyan}Uso:${NC}"
    Write-Host "    ${Green}.\build.ps1${NC}           # Solo Windows"
    Write-Host "    ${Green}.\build.ps1 -All${NC}       # Todas las plataformas"
    Write-Host "    ${Green}.\build.ps1 -Linux${NC}     # Solo Linux"
    Write-Host "    ${Green}.\build.ps1 -Mac${NC}       # Solo macOS"
} else {
    Write-Host ""
    Write-Host "  ${Red}✗ Build con $buildErrors error(es)${NC}"
    exit 1
}

if (Test-Path $SysoPath) {
    Remove-Item $SysoPath -Force -ErrorAction SilentlyContinue
}

Write-Host ""
