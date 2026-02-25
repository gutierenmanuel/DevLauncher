# Script: Limpiar ramas Git ya mergeadas
# Elimina ramas locales (y opcionalmente remotas) integradas en main/master

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

$ProtectedBranches = @("main", "master", "develop", "dev", "staging", "release")

# ─── Funciones puras ──────────────────────────────────────────────────────────

function Test-IsGitRepo {
    $null = git rev-parse --is-inside-work-tree 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-MainBranch {
    if (git show-ref --verify --quiet refs/heads/main 2>$null; $LASTEXITCODE -eq 0) { return "main" }
    if (git show-ref --verify --quiet refs/heads/master 2>$null; $LASTEXITCODE -eq 0) { return "master" }
    return $null
}

function Get-MergedBranches {
    param($Base)
    git branch --merged $Base 2>$null |
        ForEach-Object { $_.Trim().TrimStart('* ') } |
        Where-Object { $_ -ne "" -and $ProtectedBranches -notcontains $_ }
}

function Confirm-Action {
    param($Prompt, [bool]$Default = $true)
    $hint = if ($Default) { "[S/n]" } else { "[s/N]" }
    $answer = Read-Host "$Prompt $hint"
    if (-not $answer) { return $Default }
    return $answer -match '^[sySY]'
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Remove-LocalBranch {
    param($Branch)
    git branch -d $Branch 2>&1
    return $LASTEXITCODE -eq 0
}

function Remove-RemoteBranch {
    param($Remote, $Branch)
    git push $Remote --delete $Branch 2>&1
    return $LASTEXITCODE -eq 0
}

function Invoke-PruneRemotes {
    Write-Progress-Msg "Haciendo prune de referencias remotas obsoletas..."
    git remote | ForEach-Object {
        git remote prune $_ 2>$null
        Write-Success "Pruned: $_"
    }
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Limpieza de Ramas Git 🧹" "Elimina ramas locales ya mergeadas"

    if (-not (Test-IsGitRepo)) {
        Write-Host "  ${Red}✗${NC} El directorio actual no es un repositorio Git"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    $base = Get-MainBranch
    if (-not $base) {
        $base = Read-Host "No se detectó main/master. Rama base a usar"
        if (-not $base) { Write-Host "  ${Red}✗${NC} Rama base requerida"; exit 1 }
    }

    Write-Info "Rama base: ${Bold}${base}${NC}"
    Write-Host ""

    if (Confirm-Action "¿Hacer prune de referencias remotas obsoletas primero?") {
        Invoke-PruneRemotes
        Write-Host ""
    }

    Write-Progress-Msg "Buscando ramas locales mergeadas en '${base}'..."
    $candidates = @(Get-MergedBranches $base)

    if ($candidates.Count -eq 0) {
        Write-Success "No hay ramas locales mergeadas para eliminar"
        Read-Host "`nPulsa Enter para continuar"
        exit 0
    }

    Write-Host ""
    Write-Host "  ${Cyan}Ramas candidatas a eliminar:${NC}"
    $candidates | ForEach-Object { Write-Host "  ${Yellow}•${NC} $_" }
    Write-Host ""

    if (-not (Confirm-Action "¿Eliminar estas ramas locales?")) {
        Write-Info "Operación cancelada"
        Read-Host "`nPulsa Enter para continuar"
        exit 0
    }

    $deleted = 0; $failed = 0
    foreach ($branch in $candidates) {
        if (Remove-LocalBranch $branch) {
            Write-Success "Eliminada local: $branch"
            $deleted++
        } else {
            Write-Warning-Msg "No se pudo eliminar: $branch"
            $failed++
        }
    }

    # Remotas (opcional)
    $remotes = @(git remote 2>$null)
    if ($remotes.Count -gt 0) {
        Write-Host ""
        Write-Host "  ${Cyan}Remotes disponibles:${NC}"
        $remotes | ForEach-Object { Write-Host "  ${Green}•${NC} $_" }
        Write-Host ""

        if (Confirm-Action "¿Eliminar también en remotes las ramas borradas?" $false) {
            foreach ($branch in $candidates) {
                foreach ($remote in $remotes) {
                    $exists = git ls-remote --heads $remote $branch 2>$null
                    if ($exists) {
                        if (Remove-RemoteBranch $remote $branch) {
                            Write-Success "Eliminada remota: ${remote}/${branch}"
                        } else {
                            Write-Warning-Msg "No se pudo eliminar remota: ${remote}/${branch}"
                        }
                    }
                }
            }
        }
    }

    Write-Host ""
    Write-Success "Limpieza completada"
    Read-Host "`nPulsa Enter para continuar"
}

Main
