#!/bin/bash
# Script: Commit y push a todos los remotes
# Hace commit de cambios actuales (si los hay) y pushea a todos los remotes configurados

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

has_staged_changes() {
    [[ -n "$(git diff --cached --name-only 2>/dev/null)" ]]
}

has_unstaged_changes() {
    [[ -n "$(git status --porcelain 2>/dev/null)" ]]
}

list_remotes() {
    git remote 2>/dev/null
}

remote_count() {
    list_remotes | wc -l | tr -d ' '
}

# Devuelve 0 si la rama existe en un remote dado
branch_exists_in_remote() {
    local remote="$1"
    local branch="$2"
    git ls-remote --heads "$remote" "$branch" 2>/dev/null | grep -q "$branch"
}

# ─── Funciones de efecto (middleware) ─────────────────────────────────────────

stage_all() {
    progress "Añadiendo todos los cambios al staging..."
    git add -A
    success "Cambios añadidos"
}

do_commit() {
    local message="$1"
    progress "Haciendo commit: \"${message}\""
    git commit -m "$message"
    success "Commit realizado"
}

push_to_remote() {
    local remote="$1"
    local branch="$2"

    local push_flags=""
    if ! branch_exists_in_remote "$remote" "$branch"; then
        push_flags="--set-upstream"
        info "La rama '${branch}' no existe en '${remote}', se creará"
    fi

    progress "Push → ${BOLD}${remote}${NC} (${branch})..."
    # shellcheck disable=SC2086
    if git push $push_flags "$remote" "$branch" 2>&1; then
        success "Push completado → ${remote}/${branch}"
        return 0
    else
        warning "Falló el push a ${remote}/${branch}"
        return 1
    fi
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Commit & Push a todos los remotes 🚀" "Un comando para sincronizar todos tus repositorios"

    if ! is_git_repo; then
        error "El directorio actual no es un repositorio Git"
        exit 1
    fi

    local branch
    branch="$(current_branch)"
    local remotes
    remotes="$(list_remotes)"

    if [[ -z "$remotes" ]]; then
        error "No hay remotes configurados en este repositorio"
        info "Añade uno con: git remote add <nombre> <url>"
        exit 1
    fi

    # ── Mostrar situación actual ──
    info "Rama actual:  ${BOLD}${branch}${NC}"
    echo -e "  ${CYAN}Remotes configurados:${NC}"
    echo "$remotes" | while IFS= read -r r; do
        local url
        url="$(git remote get-url "$r" 2>/dev/null || echo "?")"
        echo -e "    ${GREEN}${BULLET}${NC} ${BOLD}${r}${NC} → ${GRAY}${url}${NC}"
    done
    echo ""

    # ── Gestión del commit ──
    if has_unstaged_changes || has_staged_changes; then
        echo -e "${YELLOW}${WARNING} Hay cambios en el directorio de trabajo:${NC}"
        git status --short | while IFS= read -r line; do
            echo -e "    ${DIM_GRAY}${line}${NC}"
        done
        echo ""

        if ! confirm "¿Hacer commit de estos cambios antes del push?" "y"; then
            info "Push sin nuevo commit (solo se empujarán commits ya existentes)"
        else
            # Stage
            if has_unstaged_changes && ! has_staged_changes; then
                if confirm "¿Añadir todos los archivos al commit (git add -A)?" "y"; then
                    stage_all
                    echo ""
                else
                    warning "No se añadieron archivos. Usa 'git add' manualmente y vuelve a ejecutar."
                    exit 1
                fi
            fi

            # Mensaje del commit
            local commit_msg="${DL_COMMIT_MSG:-}"
            if [[ -z "$commit_msg" ]]; then
                echo -n "  Mensaje del commit: "
                read -r commit_msg
            fi

            if [[ -z "$commit_msg" ]]; then
                error "El mensaje del commit no puede estar vacío"
                exit 1
            fi

            echo ""
            do_commit "$commit_msg"
            echo ""
        fi
    else
        info "Directorio de trabajo limpio. Se empujarán los commits existentes."
        echo ""
    fi

    # ── Confirmación final antes del push masivo ──
    local count
    count="$(echo "$remotes" | wc -l | tr -d ' ')"
    echo -e "${CYAN}Se hará push a ${BOLD}${count}${NC}${CYAN} remote(s):${NC} $(echo "$remotes" | tr '\n' ' ')"
    echo ""

    if ! confirm "¿Continuar con el push?" "y"; then
        info "Push cancelado"
        exit 0
    fi

    echo ""

    # ── Push a cada remote ──
    local ok_count=0
    local fail_count=0
    local failed_remotes=()

    while IFS= read -r remote; do
        if push_to_remote "$remote" "$branch"; then
            ok_count=$((ok_count + 1))
        else
            fail_count=$((fail_count + 1))
            failed_remotes+=("$remote")
        fi
        echo ""
    done <<< "$remotes"

    # ── Resumen ──
    echo -e "${PURPLE}════════ Resumen ════════════════${NC}"
    success "Push completado en ${ok_count}/${count} remote(s)"

    if [[ $fail_count -gt 0 ]]; then
        warning "Fallaron ${fail_count} remote(s): ${failed_remotes[*]}"
        echo ""
        read -r -p "Pulsa Enter para continuar"
        exit 1
    fi

    read -r -p "Pulsa Enter para continuar"
}

main "$@"
