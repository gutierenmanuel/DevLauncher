#!/bin/bash
# Script: Estado completo del repositorio Git
# Muestra rama actual, cambios, stash, remotes y último commit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

has_uncommitted_changes() {
    [[ -n "$(git status --porcelain 2>/dev/null)" ]]
}

stash_count() {
    git stash list 2>/dev/null | wc -l | tr -d ' '
}

upstream_status() {
    local branch="$1"
    local upstream
    upstream="$(git rev-parse --abbrev-ref "${branch}@{upstream}" 2>/dev/null || echo "")"
    if [[ -z "$upstream" ]]; then
        echo "sin upstream"
        return
    fi
    local ahead behind
    ahead="$(git rev-list "${upstream}..HEAD" --count 2>/dev/null || echo 0)"
    behind="$(git rev-list "HEAD..${upstream}" --count 2>/dev/null || echo 0)"
    echo "↑${ahead} ↓${behind} (${upstream})"
}

# ─── Funciones de presentación ────────────────────────────────────────────────

show_branch_info() {
    local branch
    branch="$(current_branch)"
    local upstream
    upstream="$(upstream_status "$branch")"
    echo -e "  ${CYAN}Rama actual:${NC}   ${BOLD}${branch}${NC}"
    echo -e "  ${CYAN}Upstream:${NC}      ${upstream}"
}

show_status() {
    local changes
    changes="$(git status --short 2>/dev/null)"
    if [[ -z "$changes" ]]; then
        echo -e "  ${GREEN}${CHECKMARK} Directorio de trabajo limpio${NC}"
    else
        echo -e "  ${YELLOW}${WARNING} Cambios pendientes:${NC}"
        echo "$changes" | while IFS= read -r line; do
            echo -e "    ${DIM_GRAY}${line}${NC}"
        done
    fi
}

show_stash() {
    local count
    count="$(stash_count)"
    if [[ "$count" -eq 0 ]]; then
        echo -e "  ${GRAY}Sin entradas en stash${NC}"
    else
        echo -e "  ${YELLOW}${count} entrada(s) en stash:${NC}"
        git stash list | head -5 | while IFS= read -r line; do
            echo -e "    ${DIM_GRAY}${line}${NC}"
        done
    fi
}

show_remotes() {
    local remotes
    remotes="$(git remote -v 2>/dev/null | grep '(fetch)' || true)"
    if [[ -z "$remotes" ]]; then
        echo -e "  ${GRAY}Sin remotes configurados${NC}"
    else
        echo "$remotes" | while IFS= read -r line; do
            local name url
            name="$(echo "$line" | awk '{print $1}')"
            url="$(echo "$line" | awk '{print $2}')"
            echo -e "  ${GREEN}${BULLET}${NC} ${BOLD}${name}${NC} → ${GRAY}${url}${NC}"
        done
    fi
}

show_last_commits() {
    echo ""
    git log --oneline --decorate --color=always -8 2>/dev/null || true
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Estado del Repositorio Git 📊" "Vista completa del repo actual"

    if ! is_git_repo; then
        error "El directorio actual no es un repositorio Git"
        exit 1
    fi

    echo -e "${PURPLE}════════ Rama & Upstream ════════${NC}"
    show_branch_info
    echo ""

    echo -e "${PURPLE}════════ Cambios ════════════════${NC}"
    show_status
    echo ""

    echo -e "${PURPLE}════════ Stash ══════════════════${NC}"
    show_stash
    echo ""

    echo -e "${PURPLE}════════ Remotes ════════════════${NC}"
    show_remotes
    echo ""

    echo -e "${PURPLE}════════ Últimos commits ════════${NC}"
    show_last_commits
    echo ""

    read -r -p "Pulsa Enter para continuar"
}

main "$@"
