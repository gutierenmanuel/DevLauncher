# run.ps1 - Instala DevLauncher en Windows.
# Siempre compila desde fuente con build-all.ps1 y luego lanza el installer.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Constantes --------------------------------------------------------------

$RootDir = $PSScriptRoot
$DistDir = Join-Path $RootDir "dist"
$VersionFile = Join-Path $RootDir "VERSION.txt"

# --- Colores / UI ------------------------------------------------------------

function Write-Info([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "✓  $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "⚠  $Message" -ForegroundColor Yellow
}

function Write-Err([string]$Message) {
    Write-Host "✗  $Message" -ForegroundColor Red
}

# --- Funciones puras ---------------------------------------------------------

function Read-Version([string]$VersionFilePath) {
    if (-not (Test-Path -LiteralPath $VersionFilePath -PathType Leaf)) {
        Write-Err "No se encontró el archivo de versión: $VersionFilePath"
        throw "VERSION_NOT_FOUND"
    }

    $firstLine = (Get-Content -LiteralPath $VersionFilePath -TotalCount 1).Trim()
    $token = ($firstLine -split '\s+')[0]
    $version = $token.TrimStart('v', 'V')

    if ([string]::IsNullOrWhiteSpace($version)) {
        Write-Err "No se pudo leer la versión desde: $VersionFilePath"
        throw "VERSION_EMPTY"
    }

    return $version
}

function Resolve-InstallerPath([string]$DistDirectory, [string]$Version) {
    return (Join-Path $DistDirectory "$Version-devlauncher-inst.exe")
}

function Binary-Ready([string]$BinaryPath) {
    return (Test-Path -LiteralPath $BinaryPath -PathType Leaf)
}

function Go-Available {
    return $null -ne (Get-Command go -ErrorAction SilentlyContinue)
}

# --- Funciones de efecto (middleware) ---------------------------------------

function Build-All([string]$ProjectRoot) {
    $buildScript = Join-Path $ProjectRoot "build-all.ps1"

    if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
        Write-Err "No se encontró el script de build: $buildScript"
        throw "BUILD_SCRIPT_NOT_FOUND"
    }

    if (-not (Go-Available)) {
        Write-Err "Go no está instalado o no está en el PATH"
        throw "GO_NOT_AVAILABLE"
    }

    Write-Info "Compilando el proyecto completo (build-all.ps1)..."
    & $buildScript
    if ($LASTEXITCODE -ne 0) {
        throw "BUILD_FAILED"
    }
}

function Launch-Installer([string]$BinaryPath) {
    Write-Ok "Ejecutando installer: $(Split-Path -Leaf $BinaryPath)"
    & $BinaryPath
    exit $LASTEXITCODE
}

# --- Orquestación (app) ------------------------------------------------------

function Main {
    $version = Read-Version -VersionFilePath $VersionFile
    $installer = Resolve-InstallerPath -DistDirectory $DistDir -Version $version

    Build-All -ProjectRoot $RootDir

    if (-not (Binary-Ready -BinaryPath $installer)) {
        Write-Err "La compilación terminó pero el installer no está disponible: $installer"
        exit 1
    }

    Write-Ok "Compilación completada"
    Launch-Installer -BinaryPath $installer
}

Main
