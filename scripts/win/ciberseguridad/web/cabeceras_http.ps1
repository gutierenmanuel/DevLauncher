# Script: Análisis de cabeceras de seguridad HTTP
# Verifica la presencia de los 8 headers de seguridad principales en una URL

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

$SecurityHeaders = @(
    @{ Name = "Strict-Transport-Security";     Short = "HSTS";    Priority = "CRÍTICO" }
    @{ Name = "Content-Security-Policy";       Short = "CSP";     Priority = "CRÍTICO" }
    @{ Name = "X-Frame-Options";               Short = "XFO";     Priority = "ALTO" }
    @{ Name = "X-Content-Type-Options";        Short = "XCTO";    Priority = "ALTO" }
    @{ Name = "Referrer-Policy";               Short = "RP";      Priority = "MEDIO" }
    @{ Name = "Permissions-Policy";            Short = "PP";      Priority = "MEDIO" }
    @{ Name = "X-XSS-Protection";              Short = "XXP";     Priority = "BAJO" }
    @{ Name = "Cross-Origin-Opener-Policy";    Short = "COOP";    Priority = "MEDIO" }
)

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Get-PriorityColor {
    param($Priority)
    switch ($Priority) {
        "CRÍTICO" { return $Red }
        "ALTO"    { return $Yellow }
        "MEDIO"   { return $Cyan }
        "BAJO"    { return $Gray }
        default   { return $Gray }
    }
}

function Get-HeaderScore {
    param($Present, $Missing)
    $total   = $Present + $Missing
    $percent = [math]::Round($Present / $total * 100)
    if ($percent -ge 75) { return "A", $Green }
    if ($percent -ge 50) { return "B", $Yellow }
    if ($percent -ge 25) { return "C", $Yellow }
    return "F", $Red
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Invoke-HeaderCheck {
    param([string]$Url)

    if ($Url -notmatch '^https?://') { $Url = "https://$Url" }

    Show-Header "Cabeceras HTTP 🔐" "Análisis de seguridad para: $Url"

    Write-Progress-Msg "Realizando petición a $Url..."
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 15 `
            -MaximumRedirection 5 -ErrorAction Stop 2>$null
        $headers  = $response.Headers
    } catch {
        Write-Host "  ${Red}✗${NC} Error al conectar: $($_.Exception.Message)"
        return
    }

    Write-Host ""
    Write-Host "  ${Cyan}Código HTTP:${NC} ${Bold}$($response.StatusCode)${NC}"
    Write-Host ""

    $present = 0; $missing = 0

    foreach ($hdr in $SecurityHeaders) {
        $value = $headers[$hdr.Name]
        $pColor = Get-PriorityColor $hdr.Priority
        $label  = "[${pColor}$($hdr.Priority.PadRight(8))${NC}]"

        if ($value) {
            $present++
            $displayVal = if ($value.Length -gt 60) { $value.Substring(0, 57) + "..." } else { $value }
            Write-Host "  ${Green}✓${NC} $label ${Bold}$($hdr.Name)${NC}"
            Write-Host "    ${Gray}→ $displayVal${NC}"
        } else {
            $missing++
            Write-Host "  ${Red}✗${NC} $label ${Bold}$($hdr.Name)${NC} — ${Gray}No presente${NC}"
        }
        Write-Host ""
    }

    $grade, $gradeColor = Get-HeaderScore $present $missing
    Write-Host "  ${Purple}════════ Resultado ══════════════${NC}"
    Write-Host "  ${Cyan}Presentes:${NC} ${Green}${present}${NC}  |  ${Cyan}Ausentes:${NC} ${Red}${missing}${NC}"
    Write-Host "  ${Cyan}Puntuación:${NC} ${gradeColor}${Bold}$grade${NC}"

    if ($missing -gt 0) {
        Write-Warning-Msg "Revisa los headers ausentes para mejorar la seguridad"
    } else {
        Write-Success "¡Todos los headers de seguridad están presentes!"
    }
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Cabeceras HTTP 🔐" "Análisis de cabeceras de seguridad"
    $url = Read-Host "  URL a analizar (ej: https://example.com)"
    if (-not $url) {
        Write-Warning-Msg "URL requerida"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    Invoke-HeaderCheck $url

    Write-Host ""
    Read-Host "Pulsa Enter para continuar"
}

Main
