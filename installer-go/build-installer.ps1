# build-installer.ps1 - Compila installer para Windows y Linux
# Uso: .\build-installer.ps1 [-SkipLauncher]

param(
    [switch]$SkipLauncher
)

$ErrorActionPreference = "Stop"

$InstallerDir = $PSScriptRoot
$RepoRoot     = Split-Path -Parent $InstallerDir
$AssetsDir    = Join-Path $InstallerDir "assets"
$OutputsDir   = Join-Path $RepoRoot "outputs"
$IconPath     = Join-Path $RepoRoot "static\devL.ico"
$VersionFile  = Join-Path $RepoRoot "VERSION.txt"
$InstallerSyso = Join-Path $InstallerDir "rsrc_windows_amd64.syso"
$UninstallerDir = Join-Path $InstallerDir "cmd\uninstaller"
$UninstallerSyso = Join-Path $UninstallerDir "rsrc_windows_amd64.syso"

if (-not (Test-Path $VersionFile)) {
    throw "No se encontró VERSION.txt"
}

$VersionToken = ((Get-Content -Path $VersionFile -TotalCount 1).Trim() -split '\s+')[0]
$VersionNumber = $VersionToken.TrimStart('v','V')
if ([string]::IsNullOrWhiteSpace($VersionNumber)) {
    throw "No se pudo leer la versión numérica desde VERSION.txt"
}

$LauncherWinName     = "$VersionNumber-devlauncher.exe"
$LauncherLinuxName   = "$VersionNumber-devlauncher-linux"
$LauncherMacName     = "$VersionNumber-devlauncher-mac"
$InstallerWinName    = "$VersionNumber-devlauncher-inst.exe"
$InstallerLinuxName  = "$VersionNumber-devlauncher-inst-linux"
$EmbeddedUninstallerWin = "uninstaller.exe"
$EmbeddedUninstallerLinux = "uninstaller-linux"
$LegacyUninstallerWin = "$VersionNumber-devlauncher-uninst.exe"
$LegacyUninstallerLinux = "$VersionNumber-devlauncher-uninst-linux"

function Write-Color($msg, $color = "White") { Write-Host $msg -ForegroundColor $color }
function Write-Step($msg)    { Write-Color "==> $msg" Cyan }
function Write-Success($msg) { Write-Color "✓  $msg" Green }
function Write-Err($msg)     { Write-Color "✗  $msg" Red }

Write-Color "Versión detectada: $VersionNumber" Cyan

function New-WindowsIconResources {
    if (-not (Test-Path $IconPath)) {
        Write-Color "  Icono no encontrado: $IconPath" Yellow
        return
    }

    Write-Step "Generando icono para ejecutables Windows..."

    & go run github.com/akavel/rsrc@latest -ico $IconPath -o $InstallerSyso 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudo generar recurso de icono para installer.exe" }

    & go run github.com/akavel/rsrc@latest -ico $IconPath -o $UninstallerSyso 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudo generar recurso de icono para uninstaller.exe" }

    Write-Color "  Icono aplicado a installer.exe y uninstaller.exe" Gray
}

if (-not (Test-Path $OutputsDir)) {
    New-Item -ItemType Directory -Path $OutputsDir -Force | Out-Null
}

# Remove stale uninstaller artifacts from previous builds
foreach ($stale in @($LegacyUninstallerWin, $LegacyUninstallerLinux)) {
    $stalePath = Join-Path $OutputsDir $stale
    if (Test-Path $stalePath) {
        Remove-Item $stalePath -Force
    }
}

# 1. Optionally rebuild launchers
if (-not $SkipLauncher) {
    Write-Step "Compilando launchers..."
    Push-Location (Join-Path $RepoRoot "launcher-go")
    try {
        if (Test-Path ".\build.ps1") {
            & .\build.ps1 -All
        } else {
            Write-Color "  build.ps1 no encontrado en launcher-go, omitiendo" Yellow
        }
    } finally { Pop-Location }
}

# 2. Prepare assets dir (clean then recreate)
Write-Step "Preparando assets..."
$subdirs = @("scripts","static")
foreach ($d in $subdirs) {
    $p = Join-Path $AssetsDir $d
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
foreach ($f in @("VERSION.txt","launcher.exe","launcher-linux","launcher-mac","uninstaller.exe","uninstaller-linux")) {
    $p = Join-Path $AssetsDir $f
    if (Test-Path $p) { Remove-Item $p -Force }
}

# 3. Copy project assets
Write-Step "Copiando assets..."
Copy-Item -Path (Join-Path $RepoRoot "scripts") -Destination (Join-Path $AssetsDir "scripts") -Recurse -Force
Copy-Item -Path (Join-Path $RepoRoot "static")  -Destination (Join-Path $AssetsDir "static")  -Recurse -Force
Copy-Item -Path (Join-Path $RepoRoot "VERSION.txt") -Destination (Join-Path $AssetsDir "VERSION.txt") -Force

$launcherMappings = @(
    @{ Source = $LauncherWinName; Dest = "launcher.exe" },
    @{ Source = $LauncherLinuxName; Dest = "launcher-linux" },
    @{ Source = $LauncherMacName; Dest = "launcher-mac" }
)

foreach ($mapping in $launcherMappings) {
    $src = Join-Path $OutputsDir $mapping.Source
    $dest = Join-Path $AssetsDir $mapping.Dest
    if (Test-Path $src) {
        Copy-Item $src -Destination $dest -Force
        Write-Color "  Copiado: $($mapping.Source) -> $($mapping.Dest)" Gray
    } else {
        Write-Color "  No encontrado en outputs: $($mapping.Source)" Yellow
    }
}

# 4. go mod tidy
Write-Step "Ejecutando go mod tidy..."
Push-Location $InstallerDir
try {
    & go mod tidy
    if ($LASTEXITCODE -ne 0) { throw "go mod tidy falló" }
} finally { Pop-Location }

# 5. Build embedded uninstallers first (required by go:embed)
Write-Step "Compilando uninstallers embebidos (windows/linux amd64)..."
Push-Location $InstallerDir
try {
    New-WindowsIconResources
    $env:GOOS = "windows"; $env:GOARCH = "amd64"
    & go build -ldflags="-s -w" -o (Join-Path $AssetsDir $EmbeddedUninstallerWin) .\cmd\uninstaller\
    if ($LASTEXITCODE -ne 0) { throw "Build Windows uninstaller falló" }

    $env:GOOS = "linux"; $env:GOARCH = "amd64"
    & go build -ldflags="-s -w" -o (Join-Path $AssetsDir $EmbeddedUninstallerLinux) .\cmd\uninstaller\
    if ($LASTEXITCODE -ne 0) { throw "Build Linux uninstaller falló" }

    Remove-Item Env:GOOS, Env:GOARCH -ErrorAction SilentlyContinue
} finally { Pop-Location }

# 6. Build installers
Write-Step "Compilando installers (windows/linux amd64)..."
Push-Location $InstallerDir
try {
    $env:GOOS = "windows"; $env:GOARCH = "amd64"
    & go build -ldflags="-s -w" -o (Join-Path $OutputsDir $InstallerWinName) .
    if ($LASTEXITCODE -ne 0) { throw "Build Windows installer falló" }

    $env:GOOS = "linux"; $env:GOARCH = "amd64"
    & go build -ldflags="-s -w" -o (Join-Path $OutputsDir $InstallerLinuxName) .
    if ($LASTEXITCODE -ne 0) { throw "Build Linux installer falló" }

    Remove-Item Env:GOOS, Env:GOARCH -ErrorAction SilentlyContinue
} finally { Pop-Location }

# 7. Clean up assets (keep only placeholders)
Write-Step "Limpiando assets temporales..."
foreach ($d in $subdirs) {
    $p = Join-Path $AssetsDir $d
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
foreach ($f in @("VERSION.txt","launcher.exe","launcher-linux","launcher-mac","uninstaller.exe","uninstaller-linux")) {
    $p = Join-Path $AssetsDir $f
    if (Test-Path $p) { Remove-Item $p -Force }
}

if (Test-Path $InstallerSyso) { Remove-Item $InstallerSyso -Force -ErrorAction SilentlyContinue }
if (Test-Path $UninstallerSyso) { Remove-Item $UninstallerSyso -Force -ErrorAction SilentlyContinue }

# 8. Report sizes
Write-Color ""
Write-Success "Build completado."
Write-Color "  Outputs: $OutputsDir" Cyan
foreach ($bin in @($InstallerWinName,$InstallerLinuxName)) {
    $p = Join-Path $OutputsDir $bin
    if (Test-Path $p) {
        $size = (Get-Item $p).Length / 1MB
        Write-Color ("  {0,-20} {1:N1} MB" -f $bin, $size) White
    }
}
Write-Color "  Uninstallers se embeben en installer-go/assets y se generan al instalar" Gray
