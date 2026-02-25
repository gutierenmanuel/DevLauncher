# Script: Enumeración de subdominios por fuerza bruta DNS
# Resuelve una lista de subdominios comunes contra un dominio objetivo

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

$WORDLIST = @(
    "www","mail","smtp","pop","imap","ftp","ssh","vpn","api","app","admin","portal"
    "dev","test","staging","qa","beta","demo","sandbox","lab","uat","pre"
    "blog","shop","store","web","mobile","cdn","media","static","assets","img"
    "auth","login","sso","oauth","accounts","id","identity","ldap"
    "ns1","ns2","mx","mx1","mx2","smtp1","smtp2","relay","mx3"
    "git","gitlab","github","bitbucket","ci","jenkins","build","deploy"
    "docs","wiki","support","help","kb","status","monitor","dashboard"
    "db","database","mysql","postgres","redis","mongo","elastic","search"
    "proxy","gateway","router","firewall","vpn2","remote","rdp","bastion"
    "panel","cpanel","webmail","roundcube","squirrelmail","autodiscover","autoconfig"
    "internal","intranet","corp","local","private","extranet"
    "cloud","aws","azure","gcp","s3","bucket"
    "backup","archive","old","legacy","v1","v2","new"
    "api2","rest","graphql","grpc","ws","socket"
)

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Resolve-Subdomain {
    param([string]$Fqdn)
    try {
        $result = Resolve-DnsName -Name $Fqdn -Type A -ErrorAction Stop 2>$null
        if ($result) {
            $ip = ($result | Where-Object { $_.Type -eq "A" } | Select-Object -First 1).IPAddress
            return $ip
        }
    } catch { }
    return $null
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Invoke-BruteForce {
    param([string]$Domain, [string[]]$Wordlist)

    Show-Header "Enumeración de Subdominios 🕸️" "Dominio: $Domain | Palabras: $($Wordlist.Count)"

    $found   = @()
    $checked = 0
    $total   = $Wordlist.Count

    foreach ($word in $Wordlist) {
        $fqdn = "$word.$Domain"
        $ip   = Resolve-Subdomain $fqdn
        $checked++

        $pct = [math]::Round($checked / $total * 100)
        Write-Host -NoNewline "`r  ${Gray}[$checked/$total] ($pct%)${NC} ${Cyan}Probando:${NC} $($fqdn.PadRight(45))"

        if ($ip) {
            $found += [PSCustomObject]@{ Subdominio = $fqdn; IP = $ip }
            Write-Host ""
            Write-Host "  ${Green}✓${NC} ${Bold}${fqdn}${NC} → ${Green}${ip}${NC}"
        }
    }

    Write-Host ""
    Write-Host ""
    Write-Host "  ${Purple}════════ Resultados ════════════════${NC}"
    Write-Success "Subdominios encontrados: ${Bold}$($found.Count)${NC} de $total probados"

    if ($found.Count -gt 0) {
        Write-Host ""
        $found | Format-Table Subdominio, IP -AutoSize | Out-String | Write-Host
    }
}

function Show-Menu {
    Show-Header "Enumeración de Subdominios 🕸️" "Brute Force DNS con wordlist incorporada"
    Write-Host "  ${Green}1.${NC} Wordlist estándar ($($WORDLIST.Count) palabras)"
    Write-Host "  ${Green}2.${NC} Wordlist desde archivo"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Menu
    $domain = Read-Host "  Dominio objetivo (ej: example.com)"
    if (-not $domain) {
        Write-Warning-Msg "Dominio requerido"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }
    $domain = $domain -replace '^https?://', '' -replace '/.*', ''

    Show-Menu
    Write-Info "Dominio: ${Bold}${domain}${NC}"
    Write-Host ""
    $opcion = Read-Host "  Opción"

    switch ($opcion) {
        "1" { Invoke-BruteForce $domain $WORDLIST }
        "2" {
            $path = Read-Host "  Ruta del archivo (una palabra por línea)"
            if (-not (Test-Path $path)) {
                Write-Host "  ${Red}✗${NC} Archivo no encontrado"
                Read-Host "`nPulsa Enter para continuar"
                exit 1
            }
            $words = Get-Content $path | Where-Object { $_ -ne "" }
            Invoke-BruteForce $domain $words
        }
        "0" { Write-Info "Saliendo"; exit 0 }
        default { Write-Warning-Msg "Opción inválida" }
    }

    Write-Host ""
    Read-Host "Pulsa Enter para continuar"
}

Main
