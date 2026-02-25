# Script: Cifrado y descifrado de archivos con AES-256
# Usa System.Security.Cryptography.Aes con PBKDF2 para derivar la clave

$ErrorActionPreference = "Stop"

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

$SALT_SIZE     = 32   # bytes
$IV_SIZE       = 16   # bytes (AES block size)
$KEY_SIZE      = 32   # 256 bits
$ITERATIONS    = 200000
$MAGIC         = [byte[]]@(0xDE, 0xC0, 0xAE, 0x52)  # cabecera propia

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Derive-Key {
    param([string]$Password, [byte[]]$Salt)
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        $Password, $Salt, $ITERATIONS,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256
    )
    $key = $pbkdf2.GetBytes($KEY_SIZE)
    $pbkdf2.Dispose()
    return $key
}

function Get-RandomBytes {
    param([int]$Count)
    $rng   = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new($Count)
    $rng.GetBytes($bytes)
    $rng.Dispose()
    return $bytes
}

function Test-MagicBytes {
    param([byte[]]$Data)
    if ($Data.Length -lt $MAGIC.Length) { return $false }
    for ($i = 0; $i -lt $MAGIC.Length; $i++) {
        if ($Data[$i] -ne $MAGIC[$i]) { return $false }
    }
    return $true
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Encrypt-File {
    param([string]$InputPath, [string]$OutputPath, [string]$Password)

    $plainData = [System.IO.File]::ReadAllBytes($InputPath)

    $salt = Get-RandomBytes $SALT_SIZE
    $iv   = Get-RandomBytes $IV_SIZE
    $key  = Derive-Key $Password $salt

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key       = $key
    $aes.IV        = $iv
    $aes.Mode      = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding   = [System.Security.Cryptography.PaddingMode]::PKCS7

    $encryptor = $aes.CreateEncryptor()
    $encrypted = $encryptor.TransformFinalBlock($plainData, 0, $plainData.Length)
    $encryptor.Dispose()
    $aes.Dispose()

    # Formato: MAGIC(4) + SALT(32) + IV(16) + CIPHERTEXT
    $output = [byte[]]::new($MAGIC.Length + $salt.Length + $iv.Length + $encrypted.Length)
    [System.Buffer]::BlockCopy($MAGIC,     0, $output, 0,                        $MAGIC.Length)
    [System.Buffer]::BlockCopy($salt,      0, $output, $MAGIC.Length,            $salt.Length)
    [System.Buffer]::BlockCopy($iv,        0, $output, $MAGIC.Length + $salt.Length, $iv.Length)
    [System.Buffer]::BlockCopy($encrypted, 0, $output, $MAGIC.Length + $salt.Length + $iv.Length, $encrypted.Length)

    [System.IO.File]::WriteAllBytes($OutputPath, $output)
}

function Decrypt-File {
    param([string]$InputPath, [string]$OutputPath, [string]$Password)

    $data = [System.IO.File]::ReadAllBytes($InputPath)

    if (-not (Test-MagicBytes $data)) {
        throw "El archivo no fue cifrado con esta herramienta (cabecera inválida)"
    }

    $offset = $MAGIC.Length

    $salt = $data[$offset..($offset + $SALT_SIZE - 1)]
    $offset += $SALT_SIZE

    $iv = $data[$offset..($offset + $IV_SIZE - 1)]
    $offset += $IV_SIZE

    $cipherData = $data[$offset..($data.Length - 1)]
    $key = Derive-Key $Password $salt

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key     = $key
    $aes.IV      = $iv
    $aes.Mode    = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $decryptor = $aes.CreateDecryptor()
    $plain     = $decryptor.TransformFinalBlock($cipherData, 0, $cipherData.Length)
    $decryptor.Dispose()
    $aes.Dispose()

    [System.IO.File]::WriteAllBytes($OutputPath, $plain)
}

function Read-SecurePassword {
    param($Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    $bstr   = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Action-Encrypt {
    Show-Header "Cifrar Archivo 🔒" "AES-256-CBC + PBKDF2 (${ITERATIONS} iteraciones)"

    $input = Read-Host "  Archivo a cifrar"
    if (-not (Test-Path $input)) { Write-Warning-Msg "Archivo no encontrado"; return }

    $default = "$input.enc"
    $output  = Read-Host "  Archivo de salida [$default]"
    if (-not $output) { $output = $default }

    $pass1 = Read-SecurePassword "  Contraseña"
    $pass2 = Read-SecurePassword "  Repetir contraseña"

    if ($pass1 -ne $pass2) {
        Write-Host "  ${Red}✗${NC} Las contraseñas no coinciden"
        return
    }

    Write-Progress-Msg "Cifrando $([System.IO.Path]::GetFileName($input))..."

    try {
        Encrypt-File $input $output $pass1
        $sizeIn  = [math]::Round((Get-Item $input).Length  / 1KB, 2)
        $sizeOut = [math]::Round((Get-Item $output).Length / 1KB, 2)
        Write-Host ""
        Write-Success "Archivo cifrado: ${Bold}$output${NC}"
        Write-Info    "Tamaño: ${sizeIn} KB → ${sizeOut} KB"
        Write-Info    "Algoritmo: AES-256-CBC | PBKDF2-SHA256 | ${ITERATIONS} iteraciones"
    } catch {
        Write-Host "  ${Red}✗${NC} Error al cifrar: $($_.Exception.Message)"
    }
}

function Action-Decrypt {
    Show-Header "Descifrar Archivo 🔓" "AES-256-CBC + PBKDF2"

    $input = Read-Host "  Archivo cifrado (.enc)"
    if (-not (Test-Path $input)) { Write-Warning-Msg "Archivo no encontrado"; return }

    $default = $input -replace '\.enc$', ''
    if ($default -eq $input) { $default = "$input.dec" }
    $output = Read-Host "  Archivo de salida [$default]"
    if (-not $output) { $output = $default }

    $pass = Read-SecurePassword "  Contraseña"

    Write-Progress-Msg "Descifrando $([System.IO.Path]::GetFileName($input))..."

    try {
        Decrypt-File $input $output $pass
        Write-Host ""
        Write-Success "Archivo descifrado: ${Bold}$output${NC}"
    } catch {
        Write-Host "  ${Red}✗${NC} Error al descifrar: $($_.Exception.Message)"
        Write-Warning-Msg "Verifica que la contraseña sea correcta"
    }
}

function Show-Menu {
    Show-Header "Cifrado AES-256 🔐" "Cifra y descifra archivos de forma segura"
    Write-Host "  ${Green}1.${NC} Cifrar archivo"
    Write-Host "  ${Green}2.${NC} Descifrar archivo"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
    Write-Host "  ${Gray}Algoritmo: AES-256-CBC  |  Derivación: PBKDF2-SHA256  |  ${ITERATIONS} iteraciones${NC}"
    Write-Host ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    while ($true) {
        Show-Menu
        $opcion = Read-Host "  Opción"
        Write-Host ""

        switch ($opcion) {
            "1" { Action-Encrypt }
            "2" { Action-Decrypt }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
