#!/bin/bash
# Script: Monitor de conexiones de red activas
# Puertos en escucha, conexiones establecidas y detección de IPs externas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_external_ip() {
    local ip="$1"
    # Devuelve 1 (externo) si no es loopback, link-local ni RFC1918
    [[ ! "$ip" =~ ^(127\.|::1|0\.0\.0\.0|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|fe80:) ]]
}

is_numeric() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

header_line() {
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

show_listening_ports() {
    progress "Puertos en escucha con proceso asociado..."
    echo ""
    header_line
    ss -tlnp 2>/dev/null \
        | awk 'NR==1 {printf "%-6s %-25s %-25s %s\n", "Proto", "Local", "Peer", "Proceso"} NR>1 {printf "%-6s %-25s %-25s %s\n", $1, $4, $5, $7}' \
        | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done
    header_line
}

show_established() {
    progress "Conexiones establecidas..."
    echo ""
    header_line
    ss -tnp state established 2>/dev/null \
        | awk 'NR==1 {printf "%-6s %-25s %-25s %s\n", "Proto", "Local", "Peer", "Proceso"} NR>1 {printf "%-6s %-25s %-25s %s\n", $1, $4, $5, $6}' \
        | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done
    header_line
}

show_external_connections() {
    progress "Conexiones hacia IPs externas..."
    echo ""
    header_line

    local found=0
    while IFS= read -r line; do
        local peer
        peer="$(echo "$line" | awk '{print $5}' | cut -d: -f1)"
        if is_external_ip "$peer"; then
            echo -e "  ${YELLOW}${BULLET}${NC} $line"
            found=$((found + 1))
        fi
    done < <(ss -tnp state established 2>/dev/null | tail -n +2)

    header_line
    echo ""
    if [[ $found -eq 0 ]]; then
        success "No se detectaron conexiones hacia IPs externas"
    else
        info "Total conexiones externas: $found"
    fi
}

filter_by_port() {
    echo ""
    read -r -p "$(echo -e "${CYAN}Puerto a filtrar: ${NC}")" port
    if ! is_numeric "$port"; then
        warning "Introduce un número de puerto válido"
        return
    fi
    echo ""
    progress "Conexiones en puerto ${port}..."
    header_line
    ss -tnp 2>/dev/null | grep ":${port}" \
        | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done || true
    header_line
}

filter_by_process() {
    echo ""
    read -r -p "$(echo -e "${CYAN}Nombre del proceso: ${NC}")" proc
    [[ -z "$proc" ]] && { warning "Nombre vacío"; return; }
    echo ""
    progress "Conexiones del proceso '${proc}'..."
    header_line
    ss -tnp 2>/dev/null | grep "$proc" \
        | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done || true
    header_line
}

live_monitor() {
    info "Monitor en tiempo real (Ctrl+C para salir)"
    echo ""
    while true; do
        clear
        echo -e "${CYAN}$(date '+%H:%M:%S') — Conexiones establecidas${NC}"
        header_line
        ss -tnp state established 2>/dev/null | head -30 || true
        header_line
        sleep 3
    done
}

show_menu() {
    clear
    show_header "Conexiones de Red 🔌" "Monitor de conexiones y puertos activos"
    echo -e "  ${GREEN}1.${NC} Puertos en escucha"
    echo -e "  ${GREEN}2.${NC} Conexiones establecidas"
    echo -e "  ${GREEN}3.${NC} Conexiones hacia IPs externas"
    echo -e "  ${GREEN}4.${NC} Filtrar por puerto"
    echo -e "  ${GREEN}5.${NC} Filtrar por proceso"
    echo -e "  ${GREEN}6.${NC} Monitor en tiempo real"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -n "  Opción: "
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Conexiones de Red 🔌" "Monitor de conexiones y puertos activos"

    check_command "ss" "SS_NOT_FOUND" || {
        handle_error "SS_NOT_FOUND" "ss no está disponible" \
            "Instálalo con: sudo apt install iproute2"
        exit 1
    }

    while true; do
        show_menu
        read -r opcion
        echo ""

        case "$opcion" in
            1) show_listening_ports ;;
            2) show_established ;;
            3) show_external_connections ;;
            4) filter_by_port ;;
            5) filter_by_process ;;
            6) live_monitor ;;
            0) info "Hasta luego"; exit 0 ;;
            *) warning "Opción inválida" ;;
        esac

        echo ""
        read -r -p "Pulsa Enter para continuar"
    done
}

main "$@"
