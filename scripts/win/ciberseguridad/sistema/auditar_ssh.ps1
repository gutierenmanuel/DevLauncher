# Script: Auditoría de configuración SSH (OpenSSH en Windows)
# Comprueba sshd_config y valida 7 controles de seguridad críticos

$ErrorActionPreference = "SilentlyContinue"

$Green  = "`e[32m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan   = "`e[36m"
$Gray   = "`e[90m"
$Red    = "`e[31m"
$Bold   = "`e[1m"
$NC     = "`e[0m"

function Show-Header {
    param($Title, $Subtitle)
    Clear-Host
    Write-Host ""
    Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
    Write-Host "${Purple}║  $Title${NC}"
    Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    Write-Host "${Gray}  $Subtitle${NC}"
    Write-Host ""
}
function Write-Progress-Msg { param($Msg); Write-Host "  ${Cyan}→${NC} $Msg" }
function Write-Success      { param($Msg); Write-Host "  ${Green}✓${NC} $Msg" }
function Write-Warning-Msg  { param($Msg); Write-Host "  ${Yellow}⚠${NC} $Msg" }
function Write-Info         { param($Msg); Write-Host "  ${Cyan}ℹ${NC} $Msg" }

$SshdConfigPaths = @(
    "$env:ProgramData\ssh\sshd_config"
    "$env:SystemRoot\System32\OpenSSH\sshd_config"
    "C:\ProgramData\ssh\sshd_config"
)

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Get-ConfigValue {
    param([string[]]$Lines, [string]$Key)
    $line = $Lines | Where-Object { $_ -match "^\s*$Key\s+" } | Select-Object -Last 1
    if (-not $line) { return $null }
    return ($line -split '\s+', 2)[1].Trim()
}

function Test-Check {
    param([string]$Description, [string]$Value, [string]$Expected, [bool]$Inverse = $false)
    $pass = if ($Inverse) { $Value -ne $Expected } else { $Value -eq $Expected }
    return [PSCustomObject]@{
        Check    = $Description
        Value    = if ($Value) { $Value } else { "(no configurado)" }
        Pass     = $pass
        Expected = $Expected
    }
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Find-SshdConfig {
    foreach ($path in $SshdConfigPaths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

function Show-ServiceStatus {
    $svc = Get-Service -Name "sshd" 2>$null
    if ($svc) {
        $color = if ($svc.Status -eq "Running") { $Green } else { $Yellow }
        Write-Host "  ${Cyan}Servicio sshd:${NC} ${color}$($svc.Status)${NC} | Inicio: $($svc.StartType)"
    } else {
        Write-Host "  ${Gray}Servicio sshd no instalado${NC}"
    }
}

function Run-Audit {
    param([string]$ConfigPath)

    Write-Progress-Msg "Leyendo configuración: $ConfigPath"
    $lines = Get-Content $ConfigPath 2>$null | Where-Object { $_ -notmatch '^\s*#' -and $_ -ne "" }

    $checks = @(
        (Test-Check "PermitRootLogin deshabilitado"     (Get-ConfigValue $lines "PermitRootLogin")     "no")
        (Test-Check "PasswordAuthentication deshabilitada" (Get-ConfigValue $lines "PasswordAuthentication") "no")
        (Test-Check "PubkeyAuthentication habilitada"   (Get-ConfigValue $lines "PubkeyAuthentication") "yes")
        (Test-Check "Puerto no estándar"               (Get-ConfigValue $lines "Port")                 "22" $true)
        (Test-Check "X11Forwarding deshabilitado"      (Get-ConfigValue $lines "X11Forwarding")       "no")
        (Test-Check "MaxAuthTries ≤ 3"                (Get-ConfigValue $lines "MaxAuthTries")         "")   # manual
        (Test-Check "Protocol 2 implícito (sin SSHv1)" (Get-ConfigValue $lines "Protocol")             "1" $true)
    )

    Write-Host ""
    Write-Host "  ${Purple}════════ Controles de Seguridad ════════${NC}"

    $passed = 0; $failed = 0
    foreach ($check in $checks) {
        $icon  = if ($check.Pass) { "${Green}✓${NC}" } else { "${Red}✗${NC}" }
        $vColor = if ($check.Pass) { $Green } else { $Yellow }
        Write-Host "  $icon ${Bold}$($check.Check)${NC}"
        Write-Host "    ${Gray}Valor actual: ${vColor}$($check.Value)${NC}"
        if ($check.Pass) { $passed++ } else { $failed++ }
    }

    # MaxAuthTries manual check
    $maxTries = Get-ConfigValue $lines "MaxAuthTries"
    if ($maxTries -and [int]$maxTries -le 3) {
        Write-Host "  ${Green}✓${NC} ${Bold}MaxAuthTries ≤ 3${NC}"
        Write-Host "    ${Gray}Valor actual: ${Green}$maxTries${NC}"
        $passed++
    } else {
        Write-Host "  ${Red}✗${NC} ${Bold}MaxAuthTries ≤ 3${NC}"
        Write-Host "    ${Gray}Valor actual: ${Yellow}${maxTries}$(if (-not $maxTries) { '(default=6)' })${NC}"
        $failed++
    }

    Write-Host ""
    Write-Host "  ${Purple}════════ Resumen ════════════════${NC}"
    Write-Host "  ${Green}Superados:${NC} $passed  |  ${Red}Fallados:${NC} $failed"

    if ($failed -eq 0) {
        Write-Success "Configuración SSH segura"
    } else {
        Write-Warning-Msg "$failed control(es) requieren atención"
    }
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Auditoría SSH 🔑" "Revisión de configuración OpenSSH en Windows"
    Show-ServiceStatus
    Write-Host ""

    $configPath = Find-SshdConfig
    if (-not $configPath) {
        Write-Warning-Msg "No se encontró sshd_config en rutas estándar"
        $manual = Read-Host "  Ruta personalizada del sshd_config (Enter para omitir)"
        if (-not $manual -or -not (Test-Path $manual)) {
            Write-Info "Auditoría omitida: archivo no disponible"
            Read-Host "`nPulsa Enter para continuar"
            exit 0
        }
        $configPath = $manual
    }

    Run-Audit $configPath

    Write-Host ""
    Read-Host "Pulsa Enter para continuar"
}

Main
