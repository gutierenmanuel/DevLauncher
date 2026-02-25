#!/bin/bash
# Script: Estado del firewall del sistema
# Detecta ufw, firewalld o iptables y muestra reglas activas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

detect_firewall() {
    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status:"; then
        echo "ufw"
    elif command -v firewall-cmd &>/dev/null && firewall-cmd --state 2>/dev/null | grep -q "running"; then
        echo "firewalld"
    elif command -v iptables &>/dev/null; then
        echo "iptables"
    else
        echo "none"
    fi
}

ufw_is_active() {
    ufw status 2>/dev/null | grep -q "Status: active"
}

firewalld_is_running() {
    firewall-cmd --state 2>/dev/null | grep -q "running"
}

iptables_has_rules() {
    local count
    count="$(iptables -L INPUT --line-numbers 2>/dev/null | grep -c "^[0-9]" || echo 0)"
    [[ "$count" -gt 0 ]]
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

show_ufw() {
    echo -e "${PURPLE}════════ UFW ════════════════════════════════════${NC}"
    echo ""

    if ufw_is_active; then
        success "UFW está ${BOLD}activo${NC}"
    else
        echo -e "  ${RED}${CROSS}${NC} UFW está ${BOLD}INACTIVO${NC}"
    fi

    echo ""
    progress "Reglas activas:"
    ufw status verbose 2>/dev/null | while IFS= read -r line; do
        echo -e "  ${DIM_GRAY}${line}${NC}"
    done

    echo ""
}

show_firewalld() {
    echo -e "${PURPLE}════════ FirewallD ══════════════════════════════${NC}"
    echo ""

    if firewalld_is_running; then
        success "firewalld está ${BOLD}activo${NC}"
    else
        echo -e "  ${RED}${CROSS}${NC} firewalld está ${BOLD}INACTIVO${NC}"
    fi

    echo ""
    local zone
    zone="$(firewall-cmd --get-default-zone 2>/dev/null || echo "desconocida")"
    info "Zona por defecto: ${BOLD}${zone}${NC}"
    echo ""

    progress "Servicios permitidos en zona ${zone}:"
    firewall-cmd --zone="$zone" --list-services 2>/dev/null \
        | tr ' ' '\n' | while IFS= read -r svc; do
            echo -e "  ${GREEN}${BULLET}${NC} ${svc}"
        done

    echo ""
    progress "Puertos permitidos:"
    firewall-cmd --zone="$zone" --list-ports 2>/dev/null \
        | tr ' ' '\n' | while IFS= read -r port; do
            [[ -n "$port" ]] && echo -e "  ${YELLOW}${BULLET}${NC} ${port}"
        done || true

    echo ""
}

show_iptables() {
    echo -e "${PURPLE}════════ iptables ═══════════════════════════════${NC}"
    echo ""

    for chain in INPUT OUTPUT FORWARD; do
        echo -e "${CYAN}── ${chain} ──${NC}"
        iptables -L "$chain" --line-numbers -n 2>/dev/null \
            | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done
        echo ""
    done

    if ! iptables_has_rules; then
        echo -e "  ${YELLOW}${WARNING}${NC} No hay reglas INPUT definidas ${DIM_GRAY}— el sistema puede estar sin filtrar tráfico${NC}"
    fi
}

show_no_firewall() {
    echo ""
    echo -e "  ${RED}${CROSS}${NC} No se detectó ningún firewall activo (ufw, firewalld, iptables)"
    echo -e "  ${YELLOW}${WARNING}${NC} El sistema puede estar completamente expuesto"
    echo ""
    info "Para instalar y activar ufw: sudo apt install ufw && sudo ufw enable"
}

show_listening_crosscheck() {
    echo ""
    echo -e "${PURPLE}════════ Puertos en escucha (para cruzar con reglas) ════${NC}"
    echo ""
    ss -tlnp 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        echo -e "  ${DIM_GRAY}${line}${NC}"
    done
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Estado del Firewall 🧱" "Reglas de red activas en el sistema"

    local fw
    fw="$(detect_firewall)"

    info "Firewall detectado: ${BOLD}${fw}${NC}"
    echo ""

    case "$fw" in
        ufw)       show_ufw ;;
        firewalld) show_firewalld ;;
        iptables)  show_iptables ;;
        none)      show_no_firewall ;;
    esac

    show_listening_crosscheck

    echo ""
    read -r -p "Pulsa Enter para continuar"
}

main "$@"
