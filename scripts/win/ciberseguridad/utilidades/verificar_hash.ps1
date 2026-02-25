# Script: Verificación de hashes de archivos
# Calcula y compara MD5, SHA1, SHA256, SHA512 con Get-FileHash nativo de PowerShell

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

$Algorithms = @("MD5", "SHA1", "SHA256", "SHA512")

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Normalize-Hash {
    param([string]$Hash)
    return $Hash.ToLower().Trim()
}

function Compare-Hashes {
    param([string]$A, [string]$B)
    return (Normalize-Hash $A) -eq (Normalize-Hash $B)
}

function Get-AlgorithmColor {
    param($Algo)
    switch ($Algo) {
        "MD5"    { return $Red }     # débil
        "SHA1"   { return $Yellow }  # débil
        "SHA256" { return $Green }   # seguro
        "SHA512" { return $Green }   # seguro
        default  { return $Cyan }
    }
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Compute-AllHashes {
    param([string]$FilePath)

    Write-Host ""
    Write-Host "  ${Purple}════════ Hashes de: $([System.IO.Path]::GetFileName($FilePath)) ════════${NC}"

    $size = (Get-Item $FilePath).Length
    Write-Info "Tamaño: $([math]::Round($size / 1KB, 2)) KB"
    Write-Host ""

    foreach ($algo in $Algorithms) {
        Write-Progress-Msg "Calculando $algo..."
        $hash = (Get-FileHash -Path $FilePath -Algorithm $algo).Hash.ToLower()
        $color = Get-AlgorithmColor $algo
        Write-Host "  ${color}$($algo.PadRight(6))${NC}  ${Bold}${hash}${NC}"
    }
}

function Compute-SingleHash {
    param([string]$FilePath, [string]$Algo)
    $hash = (Get-FileHash -Path $FilePath -Algorithm $Algo).Hash.ToLower()
    $color = Get-AlgorithmColor $Algo
    Write-Host ""
    Write-Host "  ${color}${Algo}${NC}  ${Bold}${hash}${NC}"
    return $hash
}

function Verify-Hash {
    param([string]$FilePath, [string]$Algo, [string]$Expected)

    Write-Progress-Msg "Calculando $Algo de $([System.IO.Path]::GetFileName($FilePath))..."
    $actual = (Get-FileHash -Path $FilePath -Algorithm $Algo).Hash

    Write-Host ""
    Write-Host "  ${Cyan}Esperado:${NC}  ${Gray}$(Normalize-Hash $Expected)${NC}"
    Write-Host "  ${Cyan}Calculado:${NC} ${Gray}$(Normalize-Hash $actual)${NC}"
    Write-Host ""

    if (Compare-Hashes $actual $Expected) {
        Write-Success "Hashes COINCIDEN — archivo íntegro"
    } else {
        Write-Host "  ${Red}✗${NC} Hashes NO COINCIDEN — archivo posiblemente alterado"
    }
}

function Select-Algorithm {
    Write-Host ""
    Write-Host "  Algoritmos disponibles:"
    for ($i = 0; $i -lt $Algorithms.Count; $i++) {
        $color = Get-AlgorithmColor $Algorithms[$i]
        Write-Host "  ${Green}$($i+1).${NC} ${color}$($Algorithms[$i])${NC}"
    }
    $sel = Read-Host "  Selecciona algoritmo [3=SHA256]"
    if (-not $sel -or [int]$sel -lt 1 -or [int]$sel -gt $Algorithms.Count) {
        return "SHA256"
    }
    return $Algorithms[[int]$sel - 1]
}

function Show-Menu {
    Show-Header "Verificador de Hashes 🔐" "Get-FileHash nativo de PowerShell"
    Write-Host "  ${Green}1.${NC} Calcular todos los hashes de un archivo"
    Write-Host "  ${Green}2.${NC} Calcular un hash específico"
    Write-Host "  ${Green}3.${NC} Verificar hash conocido contra archivo"
    Write-Host "  ${Green}4.${NC} Comparar dos archivos"
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
                $file = Read-Host "  Ruta del archivo"
                if (-not $file -or -not (Test-Path $file)) { Write-Warning-Msg "Archivo no encontrado"; break }
                Compute-AllHashes $file
            }
            "2" {
                $file = Read-Host "  Ruta del archivo"
                if (-not $file -or -not (Test-Path $file)) { Write-Warning-Msg "Archivo no encontrado"; break }
                $algo = Select-Algorithm
                Compute-SingleHash $file $algo
            }
            "3" {
                $file = Read-Host "  Ruta del archivo"
                if (-not $file -or -not (Test-Path $file)) { Write-Warning-Msg "Archivo no encontrado"; break }
                $algo = Select-Algorithm
                $expected = Read-Host "  Hash esperado"
                if (-not $expected) { Write-Warning-Msg "Hash requerido"; break }
                Verify-Hash $file $algo $expected
            }
            "4" {
                $file1 = Read-Host "  Primer archivo"
                $file2 = Read-Host "  Segundo archivo"
                if (-not (Test-Path $file1) -or -not (Test-Path $file2)) {
                    Write-Warning-Msg "Alguno de los archivos no existe"; break
                }
                $algo = Select-Algorithm
                $h1 = (Get-FileHash $file1 -Algorithm $algo).Hash
                $h2 = (Get-FileHash $file2 -Algorithm $algo).Hash
                Write-Host ""
                Write-Host "  ${Cyan}#1${NC}  $([System.IO.Path]::GetFileName($file1)):  ${Gray}$(($h1).ToLower())${NC}"
                Write-Host "  ${Cyan}#2${NC}  $([System.IO.Path]::GetFileName($file2)):  ${Gray}$(($h2).ToLower())${NC}"
                Write-Host ""
                if (Compare-Hashes $h1 $h2) {
                    Write-Success "Los archivos son IDÉNTICOS"
                } else {
                    Write-Host "  ${Red}✗${NC} Los archivos son DIFERENTES"
                }
            }
            "0" { Write-Info "Saliendo"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
