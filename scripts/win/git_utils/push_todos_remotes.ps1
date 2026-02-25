# Script: Commit y push a todos los remotes
# Hace commit de cambios actuales (si los hay) y pushea a todos los remotes configurados

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

function Test-IsGitRepo {
    $null = git rev-parse --is-inside-work-tree 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-CurrentBranch {
    git rev-parse --abbrev-ref HEAD 2>$null
}

function Test-HasChanges {
    $status = git status --porcelain 2>$null
    return ($null -ne $status -and $status.Trim() -ne "")
}

function Test-HasStaged {
    $staged = git diff --cached --name-only 2>$null
    return ($null -ne $staged -and $staged.Trim() -ne "")
}

function Test-BranchExistsInRemote {
    param($Remote, $Branch)
    $result = git ls-remote --heads $Remote $Branch 2>$null
    return ($null -ne $result -and $result -ne "")
}

function Confirm-Action {
    param($Prompt, [bool]$Default = $true)
    $hint = if ($Default) { "[S/n]" } else { "[s/N]" }
    $answer = Read-Host "$Prompt $hint"
    if (-not $answer) { return $Default }
    return $answer -match '^[sySY]'
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

function Invoke-StageAll {
    Write-Progress-Msg "Añadiendo todos los cambios al staging..."
    git add -A 2>&1 | Out-Null
    Write-Success "Cambios añadidos"
}

function Invoke-Commit {
    param($Message)
    Write-Progress-Msg "Haciendo commit: `"$Message`""
    git commit -m $Message 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Commit realizado"
        return $true
    }
    return $false
}

function Invoke-Push {
    param($Remote, $Branch)
    $setUpstream = -not (Test-BranchExistsInRemote $Remote $Branch)
    if ($setUpstream) {
        Write-Info "La rama '$Branch' no existe en '$Remote', se creará"
    }

    Write-Progress-Msg "Push → ${Bold}${Remote}${NC} ($Branch)..."
    if ($setUpstream) {
        git push --set-upstream $Remote $Branch 2>&1
    } else {
        git push $Remote $Branch 2>&1
    }
    return $LASTEXITCODE -eq 0
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Commit & Push a todos los remotes 🚀" "Un comando para sincronizar todos tus repositorios"

    if (-not (Test-IsGitRepo)) {
        Write-Host "  ${Red}✗${NC} El directorio actual no es un repositorio Git"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    $branch  = Get-CurrentBranch
    $remotes = @(git remote 2>$null)

    if ($remotes.Count -eq 0) {
        Write-Host "  ${Red}✗${NC} No hay remotes configurados en este repositorio"
        Write-Info "Añade uno con: git remote add <nombre> <url>"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    # Situación actual
    Write-Info "Rama actual:  ${Bold}${branch}${NC}"
    Write-Host "  ${Cyan}Remotes configurados:${NC}"
    foreach ($r in $remotes) {
        $url = git remote get-url $r 2>$null
        Write-Host "    ${Green}•${NC} ${Bold}${r}${NC} → ${Gray}${url}${NC}"
    }
    Write-Host ""

    # Gestión del commit
    if (Test-HasChanges) {
        Write-Warning-Msg "Hay cambios en el directorio de trabajo:"
        git status --short 2>$null | ForEach-Object { Write-Host "    ${Gray}$_${NC}" }
        Write-Host ""

        if (Confirm-Action "¿Hacer commit de estos cambios antes del push?") {
            if (-not (Test-HasStaged)) {
                if (Confirm-Action "¿Añadir todos los archivos (git add -A)?") {
                    Invoke-StageAll
                    Write-Host ""
                } else {
                    Write-Warning-Msg "Usa 'git add' manualmente y vuelve a ejecutar"
                    Read-Host "`nPulsa Enter para continuar"
                    exit 1
                }
            }

            $commitMsg = $env:DL_COMMIT_MSG
            if (-not $commitMsg) {
                $commitMsg = Read-Host "  Mensaje del commit"
            }
            if (-not $commitMsg) {
                Write-Host "  ${Red}✗${NC} El mensaje del commit no puede estar vacío"
                Read-Host "`nPulsa Enter para continuar"
                exit 1
            }

            Write-Host ""
            if (-not (Invoke-Commit $commitMsg)) {
                Write-Host "  ${Red}✗${NC} El commit falló"
                Read-Host "`nPulsa Enter para continuar"
                exit 1
            }
            Write-Host ""
        }
    } else {
        Write-Info "Directorio de trabajo limpio. Se empujarán los commits existentes."
        Write-Host ""
    }

    # Confirmación final
    Write-Host "  ${Cyan}Se hará push a ${Bold}$($remotes.Count)${NC}${Cyan} remote(s):${NC} $($remotes -join ', ')"
    Write-Host ""
    if (-not (Confirm-Action "¿Continuar con el push?")) {
        Write-Info "Push cancelado"; exit 0
    }
    Write-Host ""

    # Push a cada remote
    $okCount   = 0
    $failCount = 0
    $failed    = @()

    foreach ($remote in $remotes) {
        if (Invoke-Push $remote $branch) {
            $okCount++
        } else {
            $failCount++
            $failed += $remote
        }
        Write-Host ""
    }

    # Resumen
    Write-Host "  ${Purple}════════ Resumen ════════════════${NC}"
    Write-Success "Push completado en ${okCount}/$($remotes.Count) remote(s)"
    if ($failCount -gt 0) {
        Write-Warning-Msg "Fallaron $failCount remote(s): $($failed -join ', ')"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    Read-Host "`nPulsa Enter para continuar"
}

Main
