#!/bin/bash
# Script: Escáner de puertos interactivo con nmap
# Reconocimiento de puertos, servicios y sistema operativo de un objetivo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_valid_target() {
    local target="$1"
    [[ -n "$target" ]]
}

build_quick_scan_cmd() {
    local target="$1"
    echo "nmap -T4 -F $target"
}

build_full_scan_cmd() {
    local target="$1"
    echo "nmap -T4 -p- $target"
}

build_service_scan_cmd() {
    local target="$1"
    echo "nmap -T4 -sV -sC $target"
}

build_os_scan_cmd() {
    local target="$1"
    echo "sudo nmap -T4 -O $target"
}

build_output_path() {
    local target="$1"
    local safe_target="${target//\//_}"
    echo "/tmp/scan_${safe_target}_$(date +%Y%m%d_%H%M%S).txt"
}

# ─── Funciones de vista ───────────────────────────────────────────────────────

show_menu() {
    clear
    show_header "Escáner de Puertos 🔍" "Reconocimiento de red con nmap"
    echo -e "  ${GREEN}1.${NC} Escaneo rápido (puertos más comunes)"
    echo -e "  ${GREEN}2.${NC} Escaneo completo (todos los puertos)"
    echo -e "  ${GREEN}3.${NC} Detección de servicios y versiones"
    echo -e "  ${GREEN}4.${NC} Detección de sistema operativo (requiere sudo)"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -n "  Opción: "
}

ask_target() {
    echo ""
    read -r -p "$(echo -e "${CYAN}IP, dominio o rango (ej: 192.168.1.0/24): ${NC}")" target
    echo "$target"
}

ask_save_output() {
    echo ""
    confirm "¿Guardar resultado en /tmp?" "y"
}

run_scan() {
    local cmd="$1"
    local out_file="$2"

    echo ""
    progress "Ejecutando: ${BOLD}${cmd}${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ -n "$out_file" ]]; then
        eval "$cmd" | tee "$out_file"
        echo ""
        success "Resultado guardado en: $out_file"
    else
        eval "$cmd"
    fi
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Escáner de Puertos 🔍" "Reconocimiento de red con nmap"

    check_command "nmap" "NMAP_NOT_FOUND" || {
        handle_error "NMAP_NOT_FOUND" "nmap no está instalado" \
            "Instálalo con: sudo apt install nmap"
        exit 1
    }

    while true; do
        show_menu
        read -r opcion
        [[ "$opcion" == "0" ]] && { info "Hasta luego"; exit 0; }

        local target
        target="$(ask_target)"

        if ! is_valid_target "$target"; then
            warning "Debes introducir un objetivo válido"
            read -r -p "Pulsa Enter para continuar"
            continue
        fi

        local cmd
        case "$opcion" in
            1) cmd="$(build_quick_scan_cmd "$target")" ;;
            2) cmd="$(build_full_scan_cmd "$target")" ;;
            3) cmd="$(build_service_scan_cmd "$target")" ;;
            4) cmd="$(build_os_scan_cmd "$target")" ;;
            *) warning "Opción inválida"; read -r -p "Pulsa Enter"; continue ;;
        esac

        local out_file=""
        if ask_save_output; then
            out_file="$(build_output_path "$target")"
        fi

        run_scan "$cmd" "$out_file"

        echo ""
        read -r -p "Pulsa Enter para continuar"
    done
}

main "$@"
