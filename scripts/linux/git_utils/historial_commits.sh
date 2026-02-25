#!/bin/bash
# Script: Historial visual de commits Git
# Muestra el log con grafo, autores, fechas y filtros interactivos

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Constantes ───────────────────────────────────────────────────────────────

DEFAULT_LINES=20
LOG_FORMAT="%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %C(green)%an%C(reset) %s%C(red)%d%C(reset)"

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

build_log_cmd() {
    local lines="$1"
    local author_filter="$2"
    local branch_filter="$3"

    local cmd="git log --graph --color=always --date=short"
    cmd+=" --format='${LOG_FORMAT}'"
    cmd+=" -n ${lines}"
    [[ -n "$author_filter" ]] && cmd+=" --author='${author_filter}'"
    [[ -n "$branch_filter" ]] && cmd+=" ${branch_filter}"

    echo "$cmd"
}

# ─── Funciones de vista ───────────────────────────────────────────────────────

show_menu() {
    clear
    show_header "Historial de Commits 📜" "Log visual del repositorio"

    echo -e "  ${GREEN}1.${NC} Últimos commits (rama actual)"
    echo -e "  ${GREEN}2.${NC} Ver todas las ramas (grafo global)"
    echo -e "  ${GREEN}3.${NC} Filtrar por autor"
    echo -e "  ${GREEN}4.${NC} Buscar en mensajes de commit"
    echo -e "  ${GREEN}5.${NC} Commits de hoy"
    echo -e "  ${GREEN}6.${NC} Commits de esta semana"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -n "  Opción: "
}

run_log() {
    local extra_args="$1"
    echo ""
    eval "git log --graph --color=always --date=short --format='${LOG_FORMAT}' ${extra_args}" \
        | less -R --quit-if-one-screen
}

action_ultimos() {
    read -r -p "¿Cuántos commits mostrar? [${DEFAULT_LINES}]: " n
    n="${n:-$DEFAULT_LINES}"
    run_log "-n ${n}"
}

action_todas_ramas() {
    run_log "--all -n 50"
}

action_por_autor() {
    read -r -p "Nombre o email del autor: " autor
    [[ -z "$autor" ]] && { warning "Autor vacío"; return; }
    run_log "--author='${autor}' -n 30"
}

action_buscar_mensaje() {
    read -r -p "Texto a buscar en commits: " texto
    [[ -z "$texto" ]] && { warning "Texto vacío"; return; }
    run_log "--grep='${texto}' -n 30"
}

action_hoy() {
    run_log "--since='00:00:00' -n 50"
}

action_semana() {
    run_log "--since='1 week ago' -n 100"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    if ! is_git_repo; then
        show_header "Historial de Commits 📜" "Log visual del repositorio"
        error "El directorio actual no es un repositorio Git"
        exit 1
    fi

    while true; do
        show_menu
        read -r opcion
        echo ""

        case "$opcion" in
            1) action_ultimos ;;
            2) action_todas_ramas ;;
            3) action_por_autor ;;
            4) action_buscar_mensaje ;;
            5) action_hoy ;;
            6) action_semana ;;
            0) info "Hasta luego"; exit 0 ;;
            *) warning "Opción inválida" ;;
        esac

        echo ""
        read -r -p "Pulsa Enter para volver al menú"
    done
}

main "$@"
