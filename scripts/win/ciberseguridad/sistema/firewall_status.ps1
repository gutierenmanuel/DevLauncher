# Script: Estado del Firewall de Windows
# Muestra perfiles activos, reglas abiertas y conexiones permitidas

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

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Get-ProfileColor {
    param($Enabled)
    if ($Enabled -eq "True" -or $Enabled -eq $true) { return $Green }
    return $Red
}

function Format-RuleAction {
    param($Action)
    switch ($Action) {
        "Allow" { return "${Green}Allow${NC}" }
        "Block" { return "${Red}Block${NC}" }
        default { return "${Yellow}$Action${NC}" }
    }
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Show-Profiles {
    Write-Host "  ${Purple}════════ Perfiles del Firewall ════════${NC}"
    $profiles = Get-NetFirewallProfile 2>$null
    if (-not $profiles) {
        Write-Warning-Msg "No se pudo obtener información de perfiles"
        return
    }

    foreach ($p in $profiles) {
        $color   = Get-ProfileColor $p.Enabled
        $enabled = if ($p.Enabled) { "${Green}ACTIVO${NC}" } else { "${Red}INACTIVO${NC}" }
        $inbound  = if ($p.DefaultInboundAction)  { $p.DefaultInboundAction }  else { "NotConfigured" }
        $outbound = if ($p.DefaultOutboundAction) { $p.DefaultOutboundAction } else { "NotConfigured" }

        Write-Host ""
        Write-Host "  ${Bold}$($p.Name)${NC} → $enabled"
        Write-Host "    ${Cyan}Entrada por defecto:${NC}  $inbound"
        Write-Host "    ${Cyan}Salida por defecto:${NC}   $outbound"
        Write-Host "    ${Cyan}Notificaciones:${NC}       $($p.NotifyOnListen)"
    }
}

function Show-AllowedPorts {
    Write-Host ""
    Write-Host "  ${Purple}════════ Reglas Inbound Allow ════════${NC}"
    Write-Progress-Msg "Cargando reglas..."

    $rules = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True 2>$null |
             Select-Object -First 50

    if (-not $rules) {
        Write-Info "Sin reglas inbound activas"
        return
    }

    foreach ($rule in $rules) {
        $portFilter = $rule | Get-NetFirewallPortFilter 2>$null
        $port = if ($portFilter.LocalPort) { $portFilter.LocalPort } else { "any" }
        $proto = if ($portFilter.Protocol) { $portFilter.Protocol } else { "any" }
        Write-Host "  ${Green}•${NC} ${Bold}$($rule.DisplayName)${NC} ${Gray}[$proto/$port]${NC}"
    }
    Write-Info "Mostrando hasta 50 reglas. Total real puede ser mayor."
}

function Show-BlockRules {
    Write-Host ""
    Write-Host "  ${Purple}════════ Reglas Inbound Block ════════${NC}"
    $rules = Get-NetFirewallRule -Direction Inbound -Action Block -Enabled True 2>$null |
             Select-Object -First 30

    if (-not $rules) {
        Write-Info "Sin reglas de bloqueo activas"
        return
    }

    foreach ($rule in $rules) {
        Write-Host "  ${Red}✗${NC} ${Bold}$($rule.DisplayName)${NC}"
    }
}

function Search-Rule {
    $keyword = Read-Host "  Buscar regla por nombre"
    if (-not $keyword) { return }

    $rules = Get-NetFirewallRule 2>$null | Where-Object { $_.DisplayName -match $keyword }
    if (-not $rules) {
        Write-Warning-Msg "Sin resultados para '$keyword'"
        return
    }

    Write-Host ""
    $rules | ForEach-Object {
        $dir    = if ($_.Direction -eq "Inbound") { "←" } else { "→" }
        $color  = if ($_.Action -eq "Allow") { $Green } else { $Red }
        $status = if ($_.Enabled) { "${Green}●${NC}" } else { "${Gray}○${NC}" }
        Write-Host "  $status ${color}[$($_.Action)]${NC} $dir ${Bold}$($_.DisplayName)${NC} ${Gray}($($_.Profile))${NC}"
    }
    Write-Success "$($rules.Count) regla(s) encontradas"
}

function Show-Menu {
    Show-Header "Firewall de Windows 🔥" "Estado y reglas del Windows Defender Firewall"
    Write-Host "  ${Green}1.${NC} Estado de perfiles"
    Write-Host "  ${Green}2.${NC} Reglas inbound activas (Allow)"
    Write-Host "  ${Green}3.${NC} Reglas inbound de bloqueo (Block)"
    Write-Host "  ${Green}4.${NC} Buscar regla por nombre"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    while ($true) {
        Show-Menu
        $opcion = Read-Host "  Opción"
        Write-Host ""

        switch ($opcion) {
            "1" { Show-Profiles }
            "2" { Show-AllowedPorts }
            "3" { Show-BlockRules }
            "4" { Search-Rule }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
