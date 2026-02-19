# Script para ejecutar los tests de los scripts de desarrollo
# Verifica la estructura y correctitud de los scripts SIN ejecutar instalaciones

param(
    [switch]$Instaladores,   # Solo tests de instaladores
    [switch]$All,            # Todos los tests (por defecto)
    [switch]$Verbose,        # Salida detallada
    [switch]$CI              # Modo CI: sin color, exit code de Pester
)

$ErrorActionPreference = "Stop"

$Purple = if (-not $CI) { "`e[35m" } else { "" }
$Green  = if (-not $CI) { "`e[32m" } else { "" }
$Yellow = if (-not $CI) { "`e[33m" } else { "" }
$Red    = if (-not $CI) { "`e[31m" } else { "" }
$Cyan   = if (-not $CI) { "`e[36m" } else { "" }
$NC     = if (-not $CI) { "`e[0m"  } else { "" }

$TestsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║   Tests de Scripts de Desarrollo 🧪                       ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# ─── Verificar / instalar Pester ───────────────────────────────────────────────
Write-Host "${Cyan}→ Verificando Pester...${NC}"

$pester = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

if (-not $pester -or $pester.Version -lt [version]"5.0") {
    Write-Host "${Yellow}⚠ Pester 5+ no encontrado. Instalando...${NC}"
    try {
        Install-Module -Name Pester -MinimumVersion 5.0 -Force -Scope CurrentUser -SkipPublisherCheck
        Write-Host "${Green}✓ Pester instalado${NC}"
    } catch {
        Write-Host "${Red}✗ No se pudo instalar Pester: $_${NC}"
        Write-Host "${Yellow}  Intenta manualmente: Install-Module Pester -Force -Scope CurrentUser${NC}"
        exit 1
    }
} else {
    Write-Host "${Green}✓ Pester $($pester.Version) disponible${NC}"
}

Import-Module Pester -MinimumVersion 5.0

Write-Host ""

# ─── Configuración de Pester ──────────────────────────────────────────────────
$pesterConfig = New-PesterConfiguration

$pesterConfig.Output.Verbosity = if ($Verbose) { "Detailed" } else { "Normal" }
$pesterConfig.Output.CIFormat  = if ($CI) { "GithubActions" } else { "Auto" }

# Seleccionar qué tests correr
if ($Instaladores -or (-not $All -and -not $Instaladores)) {
    # Por defecto o con -Instaladores: solo tests de instaladores
    $testPath = Join-Path $TestsRoot "win\instaladores\instaladores.Tests.ps1"
    Write-Host "${Cyan}→ Ejecutando: tests/win/instaladores/${NC}"
} else {
    # -All: todos los archivos .Tests.ps1 bajo tests/
    $testPath = $TestsRoot
    Write-Host "${Cyan}→ Ejecutando: todos los tests${NC}"
}

$pesterConfig.Run.Path     = $testPath
$pesterConfig.Run.PassThru = $true

Write-Host ""

# ─── Ejecutar ────────────────────────────────────────────────────────────────
$result = Invoke-Pester -Configuration $pesterConfig

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

if ($result.FailedCount -eq 0) {
    Write-Host "${Green}✓ Todos los tests pasaron ($($result.PassedCount) passed)${NC}"
} else {
    Write-Host "${Red}✗ $($result.FailedCount) test(s) fallaron / $($result.PassedCount) pasaron${NC}"
    Write-Host ""
    Write-Host "${Yellow}Tests fallidos:${NC}"
    foreach ($failed in $result.Failed) {
        Write-Host "  ${Red}•${NC} $($failed.ExpandedName)"
        Write-Host "    ${Yellow}$($failed.ErrorRecord.Exception.Message -replace "`n", ' ')${NC}"
    }
}

Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""

# Exit code para CI
if ($CI) {
    exit $result.FailedCount
}
