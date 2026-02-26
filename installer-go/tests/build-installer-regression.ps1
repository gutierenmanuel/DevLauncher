param(
    [switch]$SkipIfLaunchersMissing = $true
)

$ErrorActionPreference = "Stop"

$TestsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallerDir = Split-Path -Parent $TestsDir
$RepoRoot = Split-Path -Parent $InstallerDir
$DistDir = Join-Path $RepoRoot "dist"
$VersionFile = Join-Path $RepoRoot "VERSION.txt"

if (-not (Test-Path $VersionFile)) {
    throw "No se encontró VERSION.txt"
}

$VersionToken = ((Get-Content -Path $VersionFile -TotalCount 1).Trim() -split '\s+')[0]
$VersionNumber = $VersionToken.TrimStart('v', 'V')

$LauncherWin = Join-Path $DistDir "$VersionNumber-devlauncher.exe"
$LauncherLinux = Join-Path $DistDir "$VersionNumber-devlauncher-linux"

if ((-not (Test-Path $LauncherWin)) -or (-not (Test-Path $LauncherLinux))) {
    if ($SkipIfLaunchersMissing) {
        Write-Host "SKIP: faltan launchers en dist. Ejecuta launcher-go/build.ps1 -All primero." -ForegroundColor Yellow
        exit 0
    }
    throw "Faltan launchers requeridos para el test de regresión"
}

Push-Location $InstallerDir
try {
    $output = & .\build-installer.ps1 -SkipLauncher 2>&1
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

$joinedOutput = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine

if ($exitCode -ne 0) {
    throw "build-installer.ps1 devolvió código $exitCode`n$joinedOutput"
}

if ($joinedOutput -match "no matching files found") {
    throw "Regresión detectada: error de go:embed por assets faltantes.`n$joinedOutput"
}

$InstallerWin = Join-Path $DistDir "$VersionNumber-devlauncher-inst.exe"
$InstallerLinux = Join-Path $DistDir "$VersionNumber-devlauncher-inst-linux"

if (-not (Test-Path $InstallerWin)) {
    throw "No se generó $InstallerWin"
}

if (-not (Test-Path $InstallerLinux)) {
    throw "No se generó $InstallerLinux"
}

Write-Host "OK: build-installer.ps1 compila sin error de go:embed y genera installers." -ForegroundColor Green
