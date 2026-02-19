# build-all.ps1 - Ejecuta el pipeline completo de build
# Compila launchers + installer/uninstaller y deja artefactos en ./outputs
# Uso:
#   .\build-all.ps1

$ErrorActionPreference = "Stop"

$RootDir = $PSScriptRoot
$LauncherBuild = Join-Path $RootDir "launcher-go\build.ps1"
$InstallerBuild = Join-Path $RootDir "installer-go\build-installer.ps1"
$OutputsDir = Join-Path $RootDir "outputs"
$VersionFile = Join-Path $RootDir "VERSION.txt"

if (-not (Test-Path $VersionFile)) {
    throw "No se encontró VERSION.txt"
}

$VersionToken = ((Get-Content -Path $VersionFile -TotalCount 1).Trim() -split '\s+')[0]
$VersionNumber = $VersionToken.TrimStart('v','V')
if ([string]::IsNullOrWhiteSpace($VersionNumber)) {
    throw "No se pudo leer la versión numérica desde VERSION.txt"
}

function Write-Step($Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok($Message) {
    Write-Host "✓  $Message" -ForegroundColor Green
}

function Write-Warn($Message) {
    Write-Host "⚠  $Message" -ForegroundColor Yellow
}

if (-not (Test-Path $LauncherBuild)) {
    throw "No se encontró launcher-go/build.ps1"
}

if (-not (Test-Path $InstallerBuild)) {
    throw "No se encontró installer-go/build-installer.ps1"
}

if (-not (Test-Path $OutputsDir)) {
    New-Item -ItemType Directory -Path $OutputsDir -Force | Out-Null
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  Build All 🏗️                                              ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

Write-Step "Compilando launchers (Windows/Linux/macOS)..."
& $LauncherBuild -All
if ($LASTEXITCODE -ne 0) {
    throw "Falló launcher-go/build.ps1"
}
Write-Ok "Launchers compilados"

Write-Step "Compilando installer + uninstaller (Windows/Linux)..."
& $InstallerBuild -SkipLauncher
if ($LASTEXITCODE -ne 0) {
    throw "Falló installer-go/build-installer.ps1"
}
Write-Ok "Installer/Uninstaller compilados"

Write-Host ""
Write-Ok "Pipeline completo finalizado"
Write-Host "Carpeta de salida: $OutputsDir" -ForegroundColor Cyan
Write-Host "Versión detectada: $VersionNumber" -ForegroundColor Cyan

$artifacts = @(
    "$VersionNumber-devlauncher.exe",
    "$VersionNumber-devlauncher-linux",
    "$VersionNumber-devlauncher-mac",
    "$VersionNumber-devlauncher-inst.exe",
    "$VersionNumber-devlauncher-inst-linux",
    "$VersionNumber-devlauncher-uninst.exe",
    "$VersionNumber-devlauncher-uninst-linux"
)

Write-Host ""
Write-Host "Artefactos:" -ForegroundColor Cyan
foreach ($artifact in $artifacts) {
    $path = Join-Path $OutputsDir $artifact
    if (Test-Path $path) {
        $sizeMB = [math]::Round((Get-Item $path).Length / 1MB, 2)
        Write-Host ("  {0,-20} {1,6} MB" -f $artifact, $sizeMB) -ForegroundColor White
    } else {
        Write-Warn "$artifact no fue generado"
    }
}

Write-Host ""
