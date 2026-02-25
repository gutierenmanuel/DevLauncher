# Script: Historial visual de commits Git
# Log interactivo con grafo, filtros por autor, mensaje y fecha

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
function Write-Warning-Msg { param($Msg); Write-Host "  ${Yellow}⚠${NC} $Msg" }
function Write-Info        { param($Msg); Write-Host "  ${Cyan}ℹ${NC} $Msg" }

$LogFormat = "%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %C(green)%an%C(reset) %s%C(red)%d%C(reset)"

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Test-IsGitRepo {
    $null = git rev-parse --is-inside-work-tree 2>$null
    return $LASTEXITCODE -eq 0
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Run-Log {
    param([string]$ExtraArgs)
    Write-Host ""
    $cmd = "git log --graph --color=always --date=short --format='$LogFormat' $ExtraArgs"
    Invoke-Expression $cmd | Out-Host -Paging
}

function Action-Ultimos {
    $n = Read-Host "¿Cuántos commits mostrar? [20]"
    if (-not $n) { $n = 20 }
    Run-Log "-n $n"
}

function Action-TodasRamas {
    Run-Log "--all -n 50"
}

function Action-PorAutor {
    $autor = Read-Host "Nombre o email del autor"
    if (-not $autor) { Write-Warning-Msg "Autor vacío"; return }
    Run-Log "--author='$autor' -n 30"
}

function Action-BuscarMensaje {
    $texto = Read-Host "Texto a buscar en commits"
    if (-not $texto) { Write-Warning-Msg "Texto vacío"; return }
    Run-Log "--grep='$texto' -n 30"
}

function Action-Hoy {
    Run-Log "--since='00:00:00' -n 50"
}

function Action-Semana {
    Run-Log "--since='1 week ago' -n 100"
}

function Show-Menu {
    Show-Header "Historial de Commits 📜" "Log visual del repositorio"
    Write-Host "  ${Green}1.${NC} Últimos commits (rama actual)"
    Write-Host "  ${Green}2.${NC} Ver todas las ramas (grafo global)"
    Write-Host "  ${Green}3.${NC} Filtrar por autor"
    Write-Host "  ${Green}4.${NC} Buscar en mensajes de commit"
    Write-Host "  ${Green}5.${NC} Commits de hoy"
    Write-Host "  ${Green}6.${NC} Commits de esta semana"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    if (-not (Test-IsGitRepo)) {
        Show-Header "Historial de Commits 📜" "Log visual del repositorio"
        Write-Host "  ${Red}✗${NC} El directorio actual no es un repositorio Git"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    while ($true) {
        Show-Menu
        $opcion = Read-Host "  Opción"
        Write-Host ""

        switch ($opcion) {
            "1" { Action-Ultimos }
            "2" { Action-TodasRamas }
            "3" { Action-PorAutor }
            "4" { Action-BuscarMensaje }
            "5" { Action-Hoy }
            "6" { Action-Semana }
            "0" { Write-Info "Hasta luego"; exit 0 }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Write-Host ""
        Read-Host "Pulsa Enter para volver al menú"
    }
}

Main
