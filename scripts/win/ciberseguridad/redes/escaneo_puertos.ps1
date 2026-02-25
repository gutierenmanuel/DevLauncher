# Script: Escaneo de puertos TCP
# Escanea rangos de puertos usando Test-NetConnection (nmap alternativo nativo de Windows)

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

# Puertos de referencia comunes
$WellKnownPorts = @{
    21  = "FTP";  22  = "SSH";   23  = "Telnet"; 25  = "SMTP"
    53  = "DNS";  80  = "HTTP";  110 = "POP3";   143 = "IMAP"
    443 = "HTTPS"; 445 = "SMB"; 3306 = "MySQL";  3389 = "RDP"
    5432 = "PostgreSQL"; 6379 = "Redis"; 8080 = "HTTP-Alt"; 8443 = "HTTPS-Alt"
}

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Get-ServiceName {
    param($Port)
    if ($WellKnownPorts.ContainsKey($Port)) { return $WellKnownPorts[$Port] }
    return "unknown"
}

function Get-PresetPorts {
    param($Mode)
    switch ($Mode) {
        "top20"  { return @(21,22,23,25,53,80,110,143,443,445,3306,3389,5432,6379,6443,8080,8443,9200,27017,5601) }
        "web"    { return @(80,443,8080,8443,8888,3000,4200,5000,9000,9443) }
        "base"   { return @(21,22,23,25,53,80,443,445,3306,3389) }
        default  { return @(21,22,80,443) }
    }
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Invoke-PortScan {
    param([string]$Target, [int[]]$Ports, [int]$TimeoutMs = 1000)

    Write-Host ""
    Write-Progress-Msg "Escaneando ${Bold}${Target}${NC} (${Bold}$($Ports.Count)${NC} puertos)..."
    Write-Host ""

    $open   = @()
    $closed = 0

    foreach ($port in $Ports) {
        $result = Test-NetConnection -ComputerName $Target -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet 2>$null
        $svc = Get-ServiceName $port
        if ($result) {
            $open += [PSCustomObject]@{ Puerto = $port; Servicio = $svc; Estado = "ABIERTO" }
            Write-Host "  ${Green}[ABIERTO]${NC}  ${Bold}$port${NC}/tcp  ${Gray}$svc${NC}"
        } else {
            $closed++
        }
    }

    Write-Host ""
    Write-Host "  ${Purple}════════ Resumen ════════════════${NC}"
    Write-Success "Abiertos:  $($open.Count)"
    Write-Info    "Cerrados:  $closed"
    Write-Info    "Total:     $($Ports.Count)"

    if ($open.Count -gt 0) {
        Write-Host ""
        Write-Warning-Msg "Puertos abiertos detectados:"
        $open | Format-Table Puerto, Servicio, Estado -AutoSize | Out-String | Write-Host
    }
}

function Show-Menu {
    Show-Header "Escaneo de Puertos 🔍" "Análisis TCP con Test-NetConnection"
    Write-Host "  ${Green}1.${NC} Puertos top 20 (más comunes)"
    Write-Host "  ${Green}2.${NC} Puertos web (HTTP/HTTPS y variantes)"
    Write-Host "  ${Green}3.${NC} Puertos base (servicio básico)"
    Write-Host "  ${Green}4.${NC} Rango personalizado (1-1024)"
    Write-Host "  ${Green}5.${NC} Puertos específicos"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Menu
    $target = Read-Host "  Objetivo (IP o dominio)"
    if (-not $target) { Write-Warning-Msg "Objetivo requerido"; exit 1 }

    while ($true) {
        Show-Menu
        Write-Info "Objetivo: ${Bold}${target}${NC}"
        Write-Host ""
        $opcion = Read-Host "  Opción"

        switch ($opcion) {
            "1" { Invoke-PortScan $target (Get-PresetPorts "top20") }
            "2" { Invoke-PortScan $target (Get-PresetPorts "web") }
            "3" { Invoke-PortScan $target (Get-PresetPorts "base") }
            "4" {
                $from = [int](Read-Host "  Puerto inicio [1]"); if (-not $from) { $from = 1 }
                $to   = [int](Read-Host "  Puerto fin [1024]"); if (-not $to)   { $to = 1024 }
                Invoke-PortScan $target ($from..$to)
            }
            "5" {
                $input  = Read-Host "  Puertos separados por coma (ej: 22,80,443)"
                $ports = $input -split ',' | ForEach-Object { [int]$_.Trim() } | Where-Object { $_ -gt 0 }
                Invoke-PortScan $target $ports
            }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Read-Host "`nPulsa Enter para volver al menú"
    }
}

Main
