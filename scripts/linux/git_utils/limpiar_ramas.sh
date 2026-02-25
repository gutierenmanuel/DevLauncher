#!/bin/bash
# Script: Limpiar ramas Git ya mergeadas
# Elimina ramas locales (y opcionalmente remotas) integradas en main/master

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

detect_main_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        echo ""
    fi
}

# Devuelve lista de ramas locales ya mergeadas en $1 (excepto protegidas)
merged_local_branches() {
    local base="$1"
    git branch --merged "$base" \
        | grep -v -E "^\*|^\s*(main|master|develop|dev|staging|release)$" \
        | sed 's/^[[:space:]]*//' \
        | grep -v "^$" || true
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

delete_local_branch() {
    local branch="$1"
    git branch -d "$branch"
}

delete_remote_branch() {
    local remote="$1"
    local branch="$2"
    git push "$remote" --delete "$branch"
}

prune_remotes() {
    progress "Haciendo prune de referencias remotas obsoletas..."
    git remote | while IFS= read -r remote; do
        git remote prune "$remote" && success "Pruned: ${remote}"
    done
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Limpieza de Ramas Git 🧹" "Elimina ramas locales ya mergeadas"

    if ! is_git_repo; then
        error "El directorio actual no es un repositorio Git"
        exit 1
    fi

    local base
    base="$(detect_main_branch)"
    if [[ -z "$base" ]]; then
        read -r -p "No se detectó main/master. Rama base a usar: " base
        [[ -z "$base" ]] && { error "Rama base requerida"; exit 1; }
    fi

    info "Rama base: ${BOLD}${base}${NC}"
    echo ""

    # ── Prune remotes ──
    if confirm "¿Hacer prune de referencias remotas obsoletas primero?" "y"; then
        prune_remotes
        echo ""
    fi

    # ── Ramas locales mergeadas ──
    progress "Buscando ramas locales mergeadas en '${base}'..."
    local candidates
    candidates="$(merged_local_branches "$base")"

    if [[ -z "$candidates" ]]; then
        success "No hay ramas locales mergeadas para eliminar"
        read -r -p "Pulsa Enter para continuar"
        exit 0
    fi

    echo ""
    echo -e "${CYAN}Ramas candidatas a eliminar:${NC}"
    echo "$candidates" | while IFS= read -r b; do
        echo -e "  ${YELLOW}${BULLET}${NC} ${b}"
    done
    echo ""

    if ! confirm "¿Eliminar estas ramas locales?" "y"; then
        info "Operación cancelada"
        read -r -p "Pulsa Enter para continuar"
        exit 0
    fi

    local deleted=0
    local failed=0
    echo "$candidates" | while IFS= read -r branch; do
        if delete_local_branch "$branch"; then
            success "Eliminada local: ${branch}"
            deleted=$((deleted + 1))
        else
            warning "No se pudo eliminar: ${branch}"
            failed=$((failed + 1))
        fi
    done

    # ── Remotas (opcional) ──
    echo ""
    local remotes
    remotes="$(git remote 2>/dev/null || true)"

    if [[ -n "$remotes" ]]; then
        echo -e "${CYAN}Remotes disponibles:${NC}"
        echo "$remotes" | while IFS= read -r r; do
            echo -e "  ${GREEN}${BULLET}${NC} ${r}"
        done
        echo ""

        if confirm "¿Eliminar también en remotes las ramas borradas?" "n"; then
            echo "$candidates" | while IFS= read -r branch; do
                echo "$remotes" | while IFS= read -r remote; do
                    if git ls-remote --heads "$remote" "$branch" 2>/dev/null | grep -q "$branch"; then
                        if delete_remote_branch "$remote" "$branch"; then
                            success "Eliminada remota: ${remote}/${branch}"
                        else
                            warning "No se pudo eliminar remota: ${remote}/${branch}"
                        fi
                    fi
                done
            done
        fi
    fi

    echo ""
    success "Limpieza completada"
    read -r -p "Pulsa Enter para continuar"
}

main "$@"
