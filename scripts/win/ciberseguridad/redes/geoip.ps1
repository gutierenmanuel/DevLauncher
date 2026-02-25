# Script: Geolocalización de IPs
# Consulta ip-api.com para obtener país, ciudad, ISP y ASN de una o varias IPs

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

function Get-GeoInfo {
    param([string]$IP)
    try {
        return Invoke-RestMethod -Uri "http://ip-api.com/json/$IP" -TimeoutSec 8 2>$null
    } catch {
        return $null
    }
}

function Get-RiskColor {
    param($IsProxy, $IsMobile)
    if ($IsProxy) { return $Red }
    if ($IsMobile) { return $Yellow }
    return $Green
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Show-GeoResult {
    param([string]$IP)
    Write-Progress-Msg "Consultando: $IP"

    $geo = Get-GeoInfo $IP
    if (-not $geo -or $geo.status -ne "success") {
        Write-Warning-Msg "No se pudo obtener información para: $IP"
        return
    }

    $riskColor = Get-RiskColor $geo.proxy $geo.mobile

    Write-Host ""
    Write-Host "  ${Purple}═══ $IP ═════════════════════════${NC}"
    Write-Host "  ${Cyan}País:${NC}        $($geo.country) ($($geo.countryCode))"
    Write-Host "  ${Cyan}Región:${NC}      $($geo.regionName) ($($geo.region))"
    Write-Host "  ${Cyan}Ciudad:${NC}      $($geo.city)"
    Write-Host "  ${Cyan}CP:${NC}          $($geo.zip)"
    Write-Host "  ${Cyan}Lat/Lon:${NC}     $($geo.lat), $($geo.lon)"
    Write-Host "  ${Cyan}Zona horaria:${NC} $($geo.timezone)"
    Write-Host "  ${Cyan}ISP:${NC}         $($geo.isp)"
    Write-Host "  ${Cyan}Organización:${NC} $($geo.org)"
    Write-Host "  ${Cyan}ASN:${NC}         $($geo.as)"
    Write-Host "  ${Cyan}Riesgo:${NC}      ${riskColor}proxy=$($geo.proxy -as [bool]), mobile=$($geo.mobile -as [bool])${NC}"
    Write-Host ""
}

function Show-MyIp {
    Write-Progress-Msg "Obteniendo IP pública..."
    try {
        $ip = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 6 2>$null).Trim()
        Write-Info "Tu IP pública: ${Bold}${ip}${NC}"
        Write-Host ""
        Show-GeoResult $ip
    } catch {
        Write-Warning-Msg "No se pudo obtener la IP pública"
    }
}

function Show-MultipleLookup {
    $raw = Read-Host "  IPs separadas por coma (ej: 8.8.8.8,1.1.1.1)"
    $ips = $raw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    foreach ($ip in $ips) {
        Show-GeoResult $ip
        Start-Sleep -Milliseconds 500
    }
}

function Show-Menu {
    Show-Header "GeoIP Lookup 🌍" "Geolocalización de direcciones IP"
    Write-Host "  ${Green}1.${NC} Mi IP pública"
    Write-Host "  ${Green}2.${NC} Consultar una IP"
    Write-Host "  ${Green}3.${NC} Consultar múltiples IPs"
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
            "1" { Show-MyIp }
            "2" {
                $ip = Read-Host "  IP a consultar"
                if ($ip) { Show-GeoResult $ip }
            }
            "3" { Show-MultipleLookup }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
