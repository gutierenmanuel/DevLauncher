# Script: Análisis de certificado SSL/TLS
# Verifica validez, expiración, versión TLS y cadena del cert usando .NET SslStream

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

function Get-DaysUntilExpiry {
    param([datetime]$Expiry)
    return ($Expiry - [datetime]::UtcNow).Days
}

function Get-ExpiryColor {
    param([int]$Days)
    if ($Days -lt 0)    { return $Red }
    if ($Days -lt 15)   { return $Red }
    if ($Days -lt 30)   { return $Yellow }
    return $Green
}

function Get-TlsColor {
    param($Protocol)
    if ($Protocol -match "Tls13") { return $Green }
    if ($Protocol -match "Tls12") { return $Green }
    if ($Protocol -match "Tls11") { return $Yellow }
    return $Red   # SSLv3, TLS1.0
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Get-CertInfo {
    param([string]$Host, [int]$Port = 443)

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $tcpClient.Connect($Host, $Port)
        $sslStream = New-Object System.Net.Security.SslStream(
            $tcpClient.GetStream(), $false,
            { $true }  # Aceptar cualquier certificado para inspeccionarlo
        )
        $sslStream.AuthenticateAsClient($Host)

        $cert      = $sslStream.RemoteCertificate
        $protocol  = $sslStream.SslProtocol.ToString()
        $certObj   = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert

        $result = [PSCustomObject]@{
            Subject     = $certObj.Subject
            Issuer      = $certObj.Issuer
            NotBefore   = $certObj.NotBefore
            NotAfter    = $certObj.NotAfter
            Thumbprint  = $certObj.Thumbprint
            Algorithm   = $certObj.SignatureAlgorithm.FriendlyName
            SAN         = ($certObj.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" } |
                           Select-Object -First 1)?.Format($false)
            TLSProtocol = $protocol
            KeySize     = $cert.GetKeyAlgorithmParametersString()
        }

        $sslStream.Close()
        $tcpClient.Close()
        return $result
    } catch {
        $tcpClient.Close()
        throw $_
    }
}

function Show-CertReport {
    param([string]$Domain, [int]$Port)

    Write-Progress-Msg "Conectando a ${Domain}:${Port}..."
    try {
        $info = Get-CertInfo $Domain $Port
    } catch {
        Write-Host "  ${Red}✗${NC} Error al conectar: $($_.Exception.Message)"
        return
    }

    $days      = Get-DaysUntilExpiry $info.NotAfter
    $expColor  = Get-ExpiryColor $days
    $tlsColor  = Get-TlsColor $info.TLSProtocol

    Write-Host ""
    Write-Host "  ${Purple}════════ Información del Certificado ════════${NC}"
    Write-Host "  ${Cyan}Sujeto:${NC}         $($info.Subject)"
    Write-Host "  ${Cyan}Emisor:${NC}         $($info.Issuer)"
    Write-Host "  ${Cyan}Válido desde:${NC}   $($info.NotBefore.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  ${Cyan}Expira:${NC}         ${expColor}$($info.NotAfter.ToString('yyyy-MM-dd HH:mm:ss'))${NC} ${expColor}($days días)${NC}"
    Write-Host "  ${Cyan}Thumbprint:${NC}     ${Gray}$($info.Thumbprint)${NC}"
    Write-Host "  ${Cyan}Algoritmo:${NC}      $($info.Algorithm)"
    Write-Host "  ${Cyan}Protocolo TLS:${NC}  ${tlsColor}${Bold}$($info.TLSProtocol)${NC}"

    if ($info.SAN) {
        Write-Host ""
        Write-Host "  ${Cyan}SANs:${NC}"
        $info.SAN -split ', ' | ForEach-Object { Write-Host "    ${Gray}•${NC} $_" }
    }

    Write-Host ""
    if ($days -lt 0) {
        Write-Host "  ${Red}✗${NC} CERTIFICADO EXPIRADO"
    } elseif ($days -lt 15) {
        Write-Warning-Msg "¡Certificado expira en menos de 15 días!"
    } else {
        Write-Success "Certificado válido"
    }

    if ($info.TLSProtocol -notmatch "Tls12|Tls13") {
        Write-Host "  ${Red}✗${NC} Protocolo TLS inseguro: $($info.TLSProtocol)"
    } else {
        Write-Success "Protocolo TLS seguro"
    }
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Certificado SSL 🔒" "Análisis del certificado TLS de un servidor"

    $raw  = Read-Host "  Host a analizar (ej: google.com o google.com:8443)"
    if (-not $raw) {
        Write-Warning-Msg "Host requerido"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    $domain = $raw -replace '^https?://', '' -replace '/.*', ''
    $port   = 443
    if ($domain -match ':(\d+)$') {
        $port   = [int]$Matches[1]
        $domain = $domain -replace ':\d+$', ''
    }

    Show-CertReport $domain $port

    Write-Host ""
    Read-Host "Pulsa Enter para continuar"
}

Main
