# Script: Gestionar Git worktrees (listar, crear, eliminar y prune)
# Permite trabajar con múltiples ramas en paralelo usando git worktree

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

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Test-IsGitRepo {
    $null = git rev-parse --is-inside-work-tree 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-DefaultBaseBranch {
    $null = git show-ref --verify --quiet refs/heads/main 2>$null
    if ($LASTEXITCODE -eq 0) { return "main" }

    $null = git show-ref --verify --quiet refs/heads/master 2>$null
    if ($LASTEXITCODE -eq 0) { return "master" }

    return (git rev-parse --abbrev-ref HEAD 2>$null)
}

function Convert-BranchToSafeName {
    param([string]$Branch)
    return $Branch -replace '/', '-'
}

function Test-LocalBranchExists {
    param([string]$Branch)
    $null = git show-ref --verify --quiet "refs/heads/$Branch" 2>$null
    return $LASTEXITCODE -eq 0
}

function Test-RemoteBranchExists {
    param([string]$Branch)
    $null = git ls-remote --exit-code --heads origin $Branch 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-RegisteredWorktreePaths {
    $paths = @()
    $porcelain = git worktree list --porcelain 2>$null
    foreach ($line in $porcelain) {
        if ($line -like "worktree *") {
            $paths += $line.Substring(9)
        }
    }
    return $paths
}

function Test-PathIsRegisteredWorktree {
    param([string]$Path)
    $normalizedTarget = [System.IO.Path]::GetFullPath($Path)
    $paths = Get-RegisteredWorktreePaths
    foreach ($registeredPath in $paths) {
        if ([System.IO.Path]::GetFullPath($registeredPath) -eq $normalizedTarget) {
            return $true
        }
    }
    return $false
}

# ─── Funciones de presentación ────────────────────────────────────────────────

function Pause-And-Continue {
    Read-Host "Pulsa Enter para continuar" | Out-Null
}

function Show-Worktrees {
    Write-Host ""
    Write-Host "  ${Purple}════════ Worktrees actuales ════════${NC}"
    git worktree list
    Write-Host ""
}

function Show-Menu {
    Write-Host "${Cyan}1)${NC} Listar worktrees"
    Write-Host "${Cyan}2)${NC} Crear worktree"
    Write-Host "${Cyan}3)${NC} Eliminar worktree"
    Write-Host "${Cyan}4)${NC} Prune de worktrees"
    Write-Host "${Cyan}0)${NC} Salir"
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function New-Worktree {
    $branch = Read-Host "Nombre de la rama para el worktree"
    if (-not $branch) {
        Write-Warning-Msg "Rama vacía. Operación cancelada"
        return
    }

    $repoName = Split-Path -Leaf (Get-Location)
    $suggestedPath = "..\$repoName-$(Convert-BranchToSafeName $branch)"
    $path = Read-Host "Ruta del nuevo worktree [$suggestedPath]"
    if (-not $path) { $path = $suggestedPath }

    Write-Progress-Msg "Creando worktree en: ${Bold}$path${NC}"

    if (Test-PathIsRegisteredWorktree $path) {
        Write-Warning-Msg "La ruta ya está registrada como worktree"
        return
    }

    if (Test-LocalBranchExists $branch) {
        git worktree add $path $branch
        Write-Success "Worktree creado para rama local '$branch'"
        return
    }

    if (Test-RemoteBranchExists $branch) {
        git worktree add --track -b $branch $path "origin/$branch"
        Write-Success "Worktree creado para rama remota 'origin/$branch'"
        return
    }

    $defaultBase = Get-DefaultBaseBranch
    if ($defaultBase) {
        $baseBranch = Read-Host "Rama base para crear '$branch' [$defaultBase]"
        if (-not $baseBranch) { $baseBranch = $defaultBase }
    } else {
        $baseBranch = Read-Host "Rama base para crear '$branch'"
    }

    if (-not $baseBranch) {
        Write-Warning-Msg "Rama base requerida. Operación cancelada"
        return
    }

    git worktree add -b $branch $path $baseBranch
    Write-Success "Worktree creado para nueva rama '$branch' desde '$baseBranch'"
}

function Remove-Worktree {
    Show-Worktrees
    $path = Read-Host "Ruta del worktree a eliminar"
    if (-not $path) {
        Write-Warning-Msg "Ruta vacía. Operación cancelada"
        return
    }

    if (-not (Test-PathIsRegisteredWorktree $path)) {
        Write-Warning-Msg "Esa ruta no aparece como worktree registrado"
        return
    }

    $confirm = Read-Host "¿Eliminar worktree '$path'? [s/N]"
    if ($confirm -notmatch '^[sSyY]$') {
        Write-Info "Operación cancelada"
        return
    }

    git worktree remove $path
    Write-Success "Worktree eliminado: $path"
}

function Invoke-WorktreePrune {
    Write-Progress-Msg "Limpiando referencias stale de worktrees..."
    git worktree prune
    Write-Success "Prune completado"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Gestión de Git Worktrees 🌳" "Administra worktrees del repo actual"

    if (-not (Test-IsGitRepo)) {
        Write-Host "  ${Red}✗${NC} El directorio actual no es un repositorio Git"
        Pause-And-Continue
        exit 1
    }

    while ($true) {
        Show-Menu
        Write-Host ""
        $option = Read-Host "Selecciona una opción"
        Write-Host ""

        switch ($option) {
            "1" { Show-Worktrees }
            "2" { New-Worktree }
            "3" { Remove-Worktree }
            "4" { Invoke-WorktreePrune }
            "0" {
                Write-Info "Saliendo de gestión de worktrees"
                Pause-And-Continue
                exit 0
            }
            default { Write-Warning-Msg "Opción inválida" }
        }

        Pause-And-Continue
        Show-Header "Gestión de Git Worktrees 🌳" "Administra worktrees del repo actual"
    }
}

Main
