# Script: Estado completo del repositorio Git
# Muestra rama actual, cambios, stash, remotes y últimos commits

$ErrorActionPreference = "Stop"

$Green  = "`e[32m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan   = "`e[36m"
$Gray   = "`e[90m"
$Red    = "`e[31m"
$Bold   = "`e[1m"
$Dim    = "`e[2m"
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

function Get-StashCount {
    $lines = git stash list 2>$null
    if (-not $lines) { return 0 }
    return @($lines).Count
}

function Get-UpstreamStatus {
    param($Branch)
    $upstream = git rev-parse --abbrev-ref "${Branch}@{upstream}" 2>$null
    if (-not $upstream) { return "sin upstream" }
    $ahead  = git rev-list "${upstream}..HEAD" --count 2>$null
    $behind = git rev-list "HEAD..${upstream}" --count 2>$null
    return "↑$ahead ↓$behind ($upstream)"
}

# ─── Funciones de presentación ────────────────────────────────────────────────

function Show-BranchInfo {
    $branch   = Get-CurrentBranch
    $upstream = Get-UpstreamStatus $branch
    Write-Host "  ${Cyan}Rama actual:${NC}  ${Bold}${branch}${NC}"
    Write-Host "  ${Cyan}Upstream:${NC}     $upstream"
}

function Show-Status {
    $changes = git status --short 2>$null
    if (-not $changes) {
        Write-Success "Directorio de trabajo limpio"
    } else {
        Write-Warning-Msg "Cambios pendientes:"
        $changes | ForEach-Object { Write-Host "    ${Gray}$_${NC}" }
    }
}

function Show-Stash {
    $count = Get-StashCount
    if ($count -eq 0) {
        Write-Host "  ${Gray}Sin entradas en stash${NC}"
    } else {
        Write-Warning-Msg "$count entrada(s) en stash:"
        git stash list 2>$null | Select-Object -First 5 |
            ForEach-Object { Write-Host "    ${Gray}$_${NC}" }
    }
}

function Show-Remotes {
    $remotes = git remote -v 2>$null | Where-Object { $_ -match '\(fetch\)' }
    if (-not $remotes) {
        Write-Host "  ${Gray}Sin remotes configurados${NC}"
    } else {
        $remotes | ForEach-Object {
            $parts = $_ -split '\s+'
            Write-Host "  ${Green}•${NC} ${Bold}$($parts[0])${NC} → ${Gray}$($parts[1])${NC}"
        }
    }
}

function Show-LastCommits {
    Write-Host ""
    git log --oneline --decorate --color=always -8 2>$null
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

function Main {
    Show-Header "Estado del Repositorio Git 📊" "Vista completa del repo actual"

    if (-not (Test-IsGitRepo)) {
        Write-Host "  ${Red}✗${NC} El directorio actual no es un repositorio Git"
        Read-Host "`nPulsa Enter para continuar"
        exit 1
    }

    Write-Host "  ${Purple}════════ Rama & Upstream ════════${NC}"
    Show-BranchInfo
    Write-Host ""

    Write-Host "  ${Purple}════════ Cambios ════════════════${NC}"
    Show-Status
    Write-Host ""

    Write-Host "  ${Purple}════════ Stash ══════════════════${NC}"
    Show-Stash
    Write-Host ""

    Write-Host "  ${Purple}════════ Remotes ════════════════${NC}"
    Show-Remotes
    Write-Host ""

    Write-Host "  ${Purple}════════ Últimos commits ════════${NC}"
    Show-LastCommits
    Write-Host ""

    Read-Host "Pulsa Enter para continuar"
}

Main
