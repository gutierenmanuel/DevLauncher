# Script: Conexiones TCP activas con procesos
# Equivalente a 'ss -tulnp' en Windows usando Get-NetTCPConnection + Get-Process

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

function Get-ProcessName {
    param([int]$Pid)
    if ($Pid -eq 0) { return "System" }
    try {
        $p = Get-Process -Id $Pid -ErrorAction Stop
        return $p.Name
    } catch {
        return "?"
    }
}

function Get-StateColor {
    param($State)
    switch ($State) {
        "Established" { return $Green }
        "Listen"      { return $Cyan }
        "TimeWait"    { return $Yellow }
        "CloseWait"   { return $Yellow }
        default        { return $Gray }
    }
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Show-Connections {
    param($Filter)
    Write-Progress-Msg "Recopilando conexiones TCP..."

    $connections = Get-NetTCPConnection 2>$null
    if ($Filter) {
        $connections = $connections | Where-Object { $_.State -eq $Filter }
    }

    if (-not $connections) {
        Write-Warning-Msg "No se encontraron conexiones"
        return
    }

    $rows = $connections | Sort-Object LocalPort | ForEach-Object {
        $proc = Get-ProcessName $_.OwningProcess
        [PSCustomObject]@{
            "Puerto Local"  = "$($_.LocalAddress):$($_.LocalPort)"
            "Puerto Remoto" = "$($_.RemoteAddress):$($_.RemotePort)"
            Estado          = $_.State
            PID             = $_.OwningProcess
            Proceso         = $proc
        }
    }

    Write-Host ""
    $rows | Format-Table -AutoSize | Out-String | Write-Host
    Write-Success "Total: $($rows.Count) conexión/ones"
}

function Show-Listeners {
    Write-Progress-Msg "Puertos en escucha (LISTEN)..."
    Show-Connections "Listen"
}

function Show-Established {
    Show-Connections "Established"
}

function Show-All {
    Show-Connections $null
}

function Show-ByProcess {
    $name = Read-Host "  Nombre del proceso"
    if (-not $name) { return }
    Write-Progress-Msg "Filtrando por proceso '$name'..."

    $procs = Get-Process -Name "*$name*" -ErrorAction SilentlyContinue
    if (-not $procs) {
        Write-Warning-Msg "No se encontraron procesos con ese nombre"
        return
    }

    $pids = $procs | Select-Object -ExpandProperty Id
    $connections = Get-NetTCPConnection 2>$null | Where-Object { $pids -contains $_.OwningProcess }

    Write-Host ""
    if ($connections) {
        $connections | ForEach-Object {
            $color = Get-StateColor $_.State
            Write-Host "  ${color}$($_.State.PadRight(14))${NC} ${Bold}$($_.LocalAddress):$($_.LocalPort)${NC} → $($_.RemoteAddress):$($_.RemotePort)"
        }
        Write-Success "Total: $($connections.Count) conexión/ones"
    } else {
        Write-Info "Sin conexiones activas para ese proceso"
    }
}

function Show-Menu {
    Show-Header "Conexiones Activas 🔌" "Monitor de conexiones TCP con procesos"
    Write-Host "  ${Green}1.${NC} Puertos en escucha (Listen)"
    Write-Host "  ${Green}2.${NC} Conexiones establecidas (Established)"
    Write-Host "  ${Green}3.${NC} Todas las conexiones TCP"
    Write-Host "  ${Green}4.${NC} Filtrar por proceso"
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
            "1" { Show-Listeners }
            "2" { Show-Established }
            "3" { Show-All }
            "4" { Show-ByProcess }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
