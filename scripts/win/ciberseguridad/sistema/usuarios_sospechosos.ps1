# Script: Detección de usuarios sospechosos
# Muestra usuarios locales con privilegios elevados, cuentas deshabilitadas y grupos críticos

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

$PrivilegedGroups = @(
    "Administrators", "Remote Desktop Users", "Power Users", "Backup Operators",
    "Network Configuration Operators", "Administradores"
)

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Get-UserRiskColor {
    param($User)
    if (-not $User.Enabled) { return $Gray }
    if (-not $User.PasswordRequired) { return $Red }
    if (-not $User.PasswordExpires) { return $Yellow }
    return $Green
}

function Get-RiskLabel {
    param($User)
    $issues = @()
    if (-not $User.Enabled) { $issues += "DESHABILITADA" }
    if (-not $User.PasswordRequired) { $issues += "SIN CONTRASEÑA" }
    if (-not $User.PasswordExpires) { $issues += "PASSWORD NO EXPIRA" }
    if ($User.PasswordLastSet -and ((Get-Date) - $User.PasswordLastSet).Days -gt 365) {
        $issues += "PASSWORD ANTIGUA (+365d)"
    }
    if ($issues.Count -eq 0) { return "OK" }
    return $issues -join ", "
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Show-LocalUsers {
    Write-Host "  ${Purple}════════ Usuarios Locales ════════${NC}"
    Write-Progress-Msg "Obteniendo usuarios..."
    $users = Get-LocalUser 2>$null

    if (-not $users) {
        Write-Warning-Msg "No se pudo obtener la lista de usuarios"
        return
    }

    foreach ($user in $users) {
        $color = Get-UserRiskColor $user
        $label = GetRiskLabel $user
        $icon  = if ($user.Enabled) { "●" } else { "○" }
        $lastLogin = if ($user.LastLogon) { $user.LastLogon.ToString('yyyy-MM-dd') } else { "Nunca" }

        Write-Host ""
        Write-Host "  ${color}$icon${NC} ${Bold}$($user.Name)${NC}"
        Write-Host "    ${Cyan}Estado:${NC}          $(if ($user.Enabled) { "${Green}Activa${NC}" } else { "${Gray}Deshabilitada${NC}" })"
        Write-Host "    ${Cyan}Último acceso:${NC}   $lastLogin"
        Write-Host "    ${Cyan}Evaluación:${NC}      ${color}$label${NC}"
    }
}

function Get-RiskLabel {
    param($User)
    $issues = @()
    if (-not $User.Enabled) { $issues += "DESHABILITADA" }
    if (-not $User.PasswordRequired) { $issues += "SIN CONTRASEÑA" }
    if (-not $User.PasswordExpires) { $issues += "PASSWORD NO EXPIRA" }
    if ($User.PasswordLastSet -and ((Get-Date) - $User.PasswordLastSet).Days -gt 365) {
        $issues += "PASSWORD ANTIGUA (+365d)"
    }
    if ($issues.Count -eq 0) { return "OK" }
    return $issues -join ", "
}

function Show-GroupMembers {
    Write-Host ""
    Write-Host "  ${Purple}════════ Grupos con Privilegios ════════${NC}"

    foreach ($groupName in $PrivilegedGroups) {
        $group = Get-LocalGroup -Name $groupName 2>$null
        if (-not $group) { continue }

        $members = Get-LocalGroupMember -Group $groupName 2>$null
        if (-not $members) { continue }

        Write-Host ""
        Write-Host "  ${Cyan}${groupName}${NC} ($($members.Count) miembro/s):"
        foreach ($m in $members) {
            $type = if ($m.ObjectClass -eq "User") { "👤" } else { "👥" }
            Write-Host "    ${Yellow}•${NC} $type ${Bold}$($m.Name)${NC} ${Gray}[$($m.PrincipalSource)]${NC}"
        }
    }
}

function Show-RecentAccounts {
    Write-Host ""
    Write-Host "  ${Purple}════════ Cuentas Creadas Recientemente ════════${NC}"
    $users = Get-LocalUser 2>$null
    $recent = $users | Where-Object {
        $_.PasswordLastSet -and ((Get-Date) - $_.PasswordLastSet).Days -le 30
    }

    if (-not $recent -or $recent.Count -eq 0) {
        Write-Info "Sin cuentas nuevas en los últimos 30 días"
    } else {
        Write-Warning-Msg "$($recent.Count) cuenta(s) con actividad reciente:"
        $recent | ForEach-Object {
            Write-Host "  ${Yellow}•${NC} ${Bold}$($_.Name)${NC} — ${Gray}$($_.PasswordLastSet.ToString('yyyy-MM-dd'))${NC}"
        }
    }
}

function Show-Menu {
    Show-Header "Usuarios Sospechosos 🔍" "Auditoría de cuentas y grupos locales de Windows"
    Write-Host "  ${Green}1.${NC} Todos los usuarios locales"
    Write-Host "  ${Green}2.${NC} Miembros de grupos con privilegios"
    Write-Host "  ${Green}3.${NC} Cuentas con actividad reciente (últimos 30 días)"
    Write-Host "  ${Green}4.${NC} Resumen completo"
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
            "1" { Show-LocalUsers }
            "2" { Show-GroupMembers }
            "3" { Show-RecentAccounts }
            "4" { Show-LocalUsers; Show-GroupMembers; Show-RecentAccounts }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
