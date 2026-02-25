# Script: Generador de contraseñas seguras
# Genera contraseñas con RNGCryptoServiceProvider en 4 modos distintos

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

# Juegos de caracteres
$Lowers   = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
$Uppers   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
$Digits   = '0123456789'.ToCharArray()
$Symbols  = '!@#$%^&*()_+-=[]{}|;:,.<>?'.ToCharArray()
$HexChars = '0123456789abcdef'.ToCharArray()

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Get-RandomBytes {
    param([int]$Count)
    $rng   = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new($Count)
    $rng.GetBytes($bytes)
    $rng.Dispose()
    return $bytes
}

function Get-RandomChar {
    param([char[]]$Charset, [byte]$Rand)
    return $Charset[$Rand % $Charset.Length]
}

function Get-Password {
    param([char[]]$Charset, [int]$Length)
    $bytes = Get-RandomBytes ($Length * 2)
    $pass  = ($bytes | Select-Object -First $Length | ForEach-Object {
        Get-RandomChar $Charset $_
    }) -join ''
    return $pass
}

function Get-PassphraseWord {
    # Genera una palabra aleatoria de entre 3-8 chars a→z
    $len   = 3 + ((Get-RandomBytes 1)[0] % 6)
    return Get-Password $Lowers $len
}

function Get-EntropyBits {
    param([char[]]$Charset, [int]$Length)
    return [math]::Round($Length * [math]::Log($Charset.Length, 2), 1)
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Generate-Standard {
    param([int]$Length = 20, [int]$Count = 5)
    $charset = $Lowers + $Uppers + $Digits + $Symbols
    Write-Host ""
    Write-Host "  ${Purple}Modo: Estándar (mayúsculas + minúsculas + dígitos + símbolos)${NC}"
    Write-Info "Entropía: ~$(Get-EntropyBits $charset $Length) bits"
    Write-Host ""
    1..$Count | ForEach-Object {
        $pwd = Get-Password $charset $Length
        Write-Host "  ${Green}•${NC} ${Bold}${pwd}${NC}"
    }
}

function Generate-Hex {
    param([int]$Length = 32, [int]$Count = 5)
    Write-Host ""
    Write-Host "  ${Purple}Modo: Hexadecimal (tokens seguros para APIs/secrets)${NC}"
    Write-Info "Entropía: ~$(Get-EntropyBits $HexChars $Length) bits"
    Write-Host ""
    1..$Count | ForEach-Object {
        $pwd = Get-Password $HexChars $Length
        Write-Host "  ${Green}•${NC} ${Bold}${pwd}${NC}"
    }
}

function Generate-Numeric {
    param([int]$Length = 12, [int]$Count = 5)
    Write-Host ""
    Write-Host "  ${Purple}Modo: Numérico (PINs y códigos)${NC}"
    Write-Info "Entropía: ~$(Get-EntropyBits $Digits $Length) bits"
    Write-Host ""
    1..$Count | ForEach-Object {
        $pwd = Get-Password $Digits $Length
        Write-Host "  ${Green}•${NC} ${Bold}${pwd}${NC}"
    }
}

function Generate-Passphrase {
    param([int]$Words = 4, [int]$Count = 5)
    Write-Host ""
    Write-Host "  ${Purple}Modo: Passphrase (fácil de recordar)${NC}"
    Write-Host ""
    1..$Count | ForEach-Object {
        $parts = 1..$Words | ForEach-Object { Get-PassphraseWord }
        $sep   = @('-', '_', '.', '!')[((Get-RandomBytes 1)[0] % 4)]
        $pass  = ($parts -join $sep) + (Get-RandomBytes 1)[0] % 100
        Write-Host "  ${Green}•${NC} ${Bold}${pass}${NC}"
    }
}

function Show-Menu {
    Show-Header "Generador de Contraseñas 🔑" "Usando System.Security.Cryptography"
    Write-Host "  ${Green}1.${NC} Contraseña estándar (mayús + minús + dígitos + símbolos)"
    Write-Host "  ${Green}2.${NC} Token hexadecimal (para APIs, secrets)"
    Write-Host "  ${Green}3.${NC} PIN numérico"
    Write-Host "  ${Green}4.${NC} Passphrase (palabras aleatorias)"
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
            "1" {
                $len = Read-Host "  Longitud [20]"; if (-not $len) { $len = 20 }
                $cnt = Read-Host "  Cantidad [5]";  if (-not $cnt) { $cnt = 5 }
                Generate-Standard ([int]$len) ([int]$cnt)
            }
            "2" {
                $len = Read-Host "  Longitud en hex [32]"; if (-not $len) { $len = 32 }
                Generate-Hex ([int]$len)
            }
            "3" {
                $len = Read-Host "  Longitud del PIN [12]"; if (-not $len) { $len = 12 }
                Generate-Numeric ([int]$len)
            }
            "4" {
                $w = Read-Host "  Número de palabras [4]"; if (-not $w) { $w = 4 }
                Generate-Passphrase ([int]$w)
            }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
