# build-installer.ps1 - Compila installer.exe e installer-linux
# Uso: .\build-installer.ps1 [-SkipLauncher]

param(
    [switch]$SkipLauncher
)

$ErrorActionPreference = "Stop"

$Root    = $PSScriptRoot
$InstallerDir = Join-Path $Root "installer-go"
$AssetsDir    = Join-Path $InstallerDir "assets"

function Write-Color($msg, $color = "White") { Write-Host $msg -ForegroundColor $color }
function Write-Step($msg)    { Write-Color "==> $msg" Cyan }
function Write-Success($msg) { Write-Color "✓  $msg" Green }
function Write-Err($msg)     { Write-Color "✗  $msg" Red }

# 1. Optionally rebuild launchers
if (-not $SkipLauncher) {
    Write-Step "Compilando launchers..."
    Push-Location (Join-Path $Root "launcher-go")
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
foreach ($f in @("VERSION.txt","launcher.exe","launcher-linux","launcher-mac")) {
    $p = Join-Path $AssetsDir $f
    if (Test-Path $p) { Remove-Item $p -Force }
}

# 3. Copy project assets
Write-Step "Copiando assets..."

Copy-Item -Path (Join-Path $Root "scripts") -Destination (Join-Path $AssetsDir "scripts") -Recurse -Force
Copy-Item -Path (Join-Path $Root "static")  -Destination (Join-Path $AssetsDir "static")  -Recurse -Force
Copy-Item -Path (Join-Path $Root "VERSION.txt") -Destination (Join-Path $AssetsDir "VERSION.txt") -Force

foreach ($bin in @("launcher.exe","launcher-linux","launcher-mac")) {
    $src = Join-Path $Root $bin
    if (Test-Path $src) {
        Copy-Item $src -Destination (Join-Path $AssetsDir $bin) -Force
        Write-Color "  Copiado: $bin" Gray
    }
}

# 4. go mod tidy
Write-Step "Ejecutando go mod tidy..."
Push-Location $InstallerDir
try {
    & go mod tidy
    if ($LASTEXITCODE -ne 0) { throw "go mod tidy falló" }
} finally { Pop-Location }

# 5. Build Windows (installer + uninstaller)
Write-Step "Compilando installer.exe (windows/amd64)..."
Push-Location $InstallerDir
try {
    $env:GOOS = "windows"; $env:GOARCH = "amd64"
    & go build -ldflags="-s -w" -o (Join-Path $Root "installer.exe") .
    if ($LASTEXITCODE -ne 0) { throw "Build Windows installer falló" }
    & go build -ldflags="-s -w" -o (Join-Path $Root "uninstaller.exe") .\cmd\uninstaller\
    if ($LASTEXITCODE -ne 0) { throw "Build Windows uninstaller falló" }
    Remove-Item Env:GOOS, Env:GOARCH -ErrorAction SilentlyContinue
} finally { Pop-Location }

# 6. Build Linux (installer + uninstaller)
Write-Step "Compilando installer-linux (linux/amd64)..."
Push-Location $InstallerDir
try {
    $env:GOOS = "linux"; $env:GOARCH = "amd64"
    & go build -ldflags="-s -w" -o (Join-Path $Root "installer-linux") .
    if ($LASTEXITCODE -ne 0) { throw "Build Linux installer falló" }
    & go build -ldflags="-s -w" -o (Join-Path $Root "uninstaller-linux") .\cmd\uninstaller\
    if ($LASTEXITCODE -ne 0) { throw "Build Linux uninstaller falló" }
    Remove-Item Env:GOOS, Env:GOARCH -ErrorAction SilentlyContinue
} finally { Pop-Location }

# 7. Clean up assets (keep only .gitkeep)
Write-Step "Limpiando assets temporales..."
foreach ($d in $subdirs) {
    $p = Join-Path $AssetsDir $d
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
foreach ($f in @("VERSION.txt","launcher.exe","launcher-linux","launcher-mac")) {
    $p = Join-Path $AssetsDir $f
    if (Test-Path $p) { Remove-Item $p -Force }
}

# 8. Report sizes
Write-Color ""
Write-Success "Build completado."
foreach ($bin in @("installer.exe","installer-linux","uninstaller.exe","uninstaller-linux")) {
    $p = Join-Path $Root $bin
    if (Test-Path $p) {
        $size = (Get-Item $p).Length / 1MB
        Write-Color ("  {0,-20} {1:N1} MB" -f $bin, $size) White
    }
}
