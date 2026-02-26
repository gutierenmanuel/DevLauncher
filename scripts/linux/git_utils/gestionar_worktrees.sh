#!/bin/bash
# Script: Gestionar Git worktrees (listar, crear, eliminar y prune)
# Permite trabajar con múltiples ramas en paralelo usando git worktree

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

detect_base_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
    fi
}

sanitize_branch_name() {
    local branch="$1"
    echo "${branch//\//-}"
}

local_branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/${branch}"
}

remote_branch_exists() {
    local branch="$1"
    git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
}

worktree_path_registered() {
    local path="$1"
    git worktree list --porcelain | awk '/^worktree / {print substr($0, 10)}' | grep -Fxq "$path"
}

# ─── Funciones de presentación ────────────────────────────────────────────────

pause_and_continue() {
    read -r -p "Pulsa Enter para continuar"
}

show_worktrees() {
    echo ""
    echo -e "${PURPLE}════════ Worktrees actuales ════════${NC}"
    git worktree list
    echo ""
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

create_worktree() {
    local branch
    read -r -p "Nombre de la rama para el worktree: " branch
    if [[ -z "$branch" ]]; then
        warning "Rama vacía. Operación cancelada"
        return
    fi

    local repo_name
    repo_name="$(basename "$(pwd)")"
    local suggested_path
    suggested_path="../${repo_name}-$(sanitize_branch_name "$branch")"

    local path
    read -r -p "Ruta del nuevo worktree [${suggested_path}]: " path
    path="${path:-$suggested_path}"

    progress "Creando worktree en: ${BOLD}${path}${NC}"

    if worktree_path_registered "$path"; then
        warning "La ruta ya está registrada como worktree"
        return
    fi

    if local_branch_exists "$branch"; then
        git worktree add "$path" "$branch"
        success "Worktree creado para rama local '${branch}'"
        return
    fi

    if remote_branch_exists "$branch"; then
        git worktree add --track -b "$branch" "$path" "origin/$branch"
        success "Worktree creado para rama remota 'origin/${branch}'"
        return
    fi

    local base
    base="$(detect_base_branch)"
    if [[ -z "$base" ]]; then
        read -r -p "Rama base para crear '${branch}': " base
    else
        read -r -p "Rama base para crear '${branch}' [${base}]: " input_base
        base="${input_base:-$base}"
    fi

    if [[ -z "$base" ]]; then
        warning "Rama base requerida. Operación cancelada"
        return
    fi

    git worktree add -b "$branch" "$path" "$base"
    success "Worktree creado para nueva rama '${branch}' desde '${base}'"
}

remove_worktree() {
    show_worktrees
    local path
    read -r -p "Ruta del worktree a eliminar: " path
    if [[ -z "$path" ]]; then
        warning "Ruta vacía. Operación cancelada"
        return
    fi

    if ! worktree_path_registered "$path"; then
        warning "Esa ruta no aparece como worktree registrado"
        return
    fi

    if ! confirm "¿Eliminar worktree '${path}'?" "n"; then
        info "Operación cancelada"
        return
    fi

    git worktree remove "$path"
    success "Worktree eliminado: ${path}"
}

prune_worktrees() {
    progress "Limpiando referencias stale de worktrees..."
    git worktree prune
    success "Prune completado"
}

show_menu() {
    echo -e "${CYAN}1)${NC} Listar worktrees"
    echo -e "${CYAN}2)${NC} Crear worktree"
    echo -e "${CYAN}3)${NC} Eliminar worktree"
    echo -e "${CYAN}4)${NC} Prune de worktrees"
    echo -e "${CYAN}0)${NC} Salir"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Gestión de Git Worktrees 🌳" "Administra worktrees del repo actual"

    if ! is_git_repo; then
        error "El directorio actual no es un repositorio Git"
        pause_and_continue
        exit 1
    fi

    while true; do
        show_menu
        echo ""
        read -r -p "Selecciona una opción: " option
        echo ""

        case "$option" in
            1) show_worktrees ;;
            2) create_worktree ;;
            3) remove_worktree ;;
            4) prune_worktrees ;;
            0)
                info "Saliendo de gestión de worktrees"
                pause_and_continue
                exit 0
                ;;
            *)
                warning "Opción inválida"
                ;;
        esac

        pause_and_continue
        show_header "Gestión de Git Worktrees 🌳" "Administra worktrees del repo actual"
    done
}

main "$@"
