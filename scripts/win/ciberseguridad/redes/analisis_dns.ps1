# Script: Análisis DNS completo
# Resuelve registros DNS (A, AAAA, MX, NS, TXT, CNAME, SOA) y consulta reputación del dominio

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

function Get-DnsRecords {
    param([string]$Domain, [string]$Type)
    try {
        return Resolve-DnsName -Name $Domain -Type $Type -ErrorAction Stop 2>$null
    } catch {
        return $null
    }
}

function Format-RecordValue {
    param($Record)
    switch ($Record.Type) {
        "A"     { return $Record.IPAddress }
        "AAAA"  { return $Record.IPAddress }
        "MX"    { return "$($Record.NameExchange) (prio: $($Record.Preference))" }
        "NS"    { return $Record.NameHost }
        "CNAME" { return $Record.NameHost }
        "TXT"   { return ($Record.Strings -join " ") }
        "SOA"   { return "$($Record.PrimaryServer) - mbox: $($Record.MailboxDomainName)" }
        default { return $Record.ToString() }
    }
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Show-RecordType {
    param([string]$Domain, [string]$Type)
    Write-Host "  ${Cyan}${Type}:${NC}"
    $records = Get-DnsRecords $Domain $Type
    if (-not $records) {
        Write-Host "    ${Gray}(sin registros)${NC}"
        return
    }
    $records | ForEach-Object {
        $val = Format-RecordValue $_
        Write-Host "    ${Green}•${NC} ${Gray}${val}${NC}"
    }
}

function Show-FullAnalysis {
    param([string]$Domain)

    Show-Header "Análisis DNS 🌐" "Resolución completa para: $Domain"

    $types = @("A", "AAAA", "MX", "NS", "TXT", "CNAME", "SOA")
    foreach ($type in $types) {
        Write-Progress-Msg "Consultando $type..."
        Show-RecordType $Domain $type
        Write-Host ""
    }

    # Reputación vía rdap / ip-api
    Write-Host "  ${Purple}════════ Reputación / Info extra ════════${NC}"
    Write-Progress-Msg "Consultando información del dominio..."
    try {
        $aRecord = Get-DnsRecords $Domain "A" | Select-Object -First 1
        if ($aRecord) {
            $ip = $aRecord.IPAddress
            $geo = Invoke-RestMethod -Uri "http://ip-api.com/json/$ip" -TimeoutSec 6 2>$null
            if ($geo -and $geo.status -eq "success") {
                Write-Host "  ${Cyan}IP:${NC}          ${Bold}${ip}${NC}"
                Write-Host "  ${Cyan}País:${NC}        $($geo.country) ($($geo.countryCode))"
                Write-Host "  ${Cyan}Ciudad:${NC}      $($geo.city)"
                Write-Host "  ${Cyan}ISP:${NC}         $($geo.isp)"
                Write-Host "  ${Cyan}ASN:${NC}         $($geo.as)"
            }
        }
    } catch {
        Write-Warning-Msg "No se pudo obtener info de reputación"
    }

    Write-Host ""
    Write-Success "Análisis completado"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Análisis DNS 🌐" "Consulta todos los registros DNS de un dominio"
    $domain = Read-Host "  Dominio a analizar (ej: google.com)"
    if (-not $domain) {
        Write-Warning-Msg "Dominio requerido"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    $domain = $domain -replace '^https?://', '' -replace '/.*', ''

    Show-FullAnalysis $domain

    Read-Host "`nPulsa Enter para continuar"
}

Main
