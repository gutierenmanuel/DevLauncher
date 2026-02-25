#!/bin/bash
# Script: Análisis de cabeceras HTTP de seguridad
# Evalúa la presencia y configuración de cabeceras de seguridad en un sitio web

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

normalize_url() {
    local url="$1"
    # Añadir https:// si no tiene esquema
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "https://${url}"
    else
        echo "$url"
    fi
}

is_valid_url() {
    [[ -n "$1" ]]
}

header_present() {
    local headers="$1"
    local name="$2"
    echo "$headers" | grep -qi "^${name}:"
}

extract_header_value() {
    local headers="$1"
    local name="$2"
    echo "$headers" | grep -i "^${name}:" | cut -d: -f2- | xargs
}

# Evalúa si HSTS tiene max-age suficiente (>= 6 meses)
hsts_is_strong() {
    local value="$1"
    local max_age
    max_age="$(echo "$value" | grep -oE 'max-age=[0-9]+' | cut -d= -f2 || echo 0)"
    [[ "$max_age" -ge 15768000 ]]  # 6 meses
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

fetch_headers() {
    local url="$1"
    curl -sI --max-time 15 --location "$url" 2>/dev/null | tr -d '\r'
}

check_header() {
    local headers="$1"
    local name="$2"
    local description="$3"

    if header_present "$headers" "$name"; then
        local value
        value="$(extract_header_value "$headers" "$name")"
        echo -e "  ${GREEN}${CHECKMARK}${NC} ${BOLD}${name}${NC}"
        echo -e "     ${GRAY}${value}${NC}"
    else
        echo -e "  ${RED}${CROSS}${NC} ${BOLD}${name}${NC} ${DIM_GRAY}— ${description}${NC}"
    fi
}

check_hsts() {
    local headers="$1"
    local name="Strict-Transport-Security"
    if header_present "$headers" "$name"; then
        local value
        value="$(extract_header_value "$headers" "$name")"
        if hsts_is_strong "$value"; then
            echo -e "  ${GREEN}${CHECKMARK}${NC} ${BOLD}${name}${NC}"
        else
            echo -e "  ${YELLOW}${WARNING}${NC} ${BOLD}${name}${NC} ${DIM_GRAY}— max-age demasiado corto (<6 meses)${NC}"
        fi
        echo -e "     ${GRAY}${value}${NC}"
    else
        echo -e "  ${RED}${CROSS}${NC} ${BOLD}${name}${NC} ${DIM_GRAY}— HSTS no configurado${NC}"
    fi
}

show_server_info() {
    local headers="$1"

    echo ""
    echo -e "${CYAN}── Información del servidor ──────────────────────${NC}"

    for h in Server X-Powered-By X-AspNet-Version X-Generator; do
        if header_present "$headers" "$h"; then
            local val
            val="$(extract_header_value "$headers" "$h")"
            echo -e "  ${YELLOW}${WARNING}${NC} ${BOLD}${h}${NC}: ${val} ${DIM_GRAY}(información expuesta)${NC}"
        fi
    done

    local status
    status="$(echo "$headers" | head -1)"
    echo -e "  ${CYAN}Status:${NC} ${status}"
}

analyze_url() {
    local raw_url="$1"
    local url
    url="$(normalize_url "$raw_url")"

    progress "Consultando cabeceras de: ${BOLD}${url}${NC}"
    local headers
    headers="$(fetch_headers "$url")"

    if [[ -z "$headers" ]]; then
        error "No se pudieron obtener las cabeceras. ¿El sitio está disponible?"
        return 1
    fi

    echo ""
    echo -e "${PURPLE}════════ Cabeceras de Seguridad ════════════════${NC}"
    echo ""

    check_hsts "$headers"
    check_header "$headers" "Content-Security-Policy"    "Previene XSS e inyección de contenido"
    check_header "$headers" "X-Frame-Options"            "Previene clickjacking"
    check_header "$headers" "X-Content-Type-Options"     "Previene MIME sniffing"
    check_header "$headers" "Referrer-Policy"            "Controla información del referrer"
    check_header "$headers" "Permissions-Policy"         "Controla acceso a APIs del navegador"
    check_header "$headers" "Cross-Origin-Opener-Policy" "Aísla el contexto de navegación"
    check_header "$headers" "Cross-Origin-Resource-Policy" "Controla compartición de recursos"

    show_server_info "$headers"
    echo ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Cabeceras HTTP de Seguridad 🔒" "Análisis de headers en sitios web"

    check_command "curl" "CURL_NOT_FOUND" || {
        handle_error "CURL_NOT_FOUND" "curl no está instalado" \
            "Instálalo con: sudo apt install curl"
        exit 1
    }

    while true; do
        echo ""
        read -r -p "$(echo -e "${CYAN}URL a analizar (0 para salir): ${NC}")" input
        [[ "$input" == "0" || -z "$input" ]] && { info "Hasta luego"; exit 0; }

        if ! is_valid_url "$input"; then
            warning "URL no válida"
        else
            analyze_url "$input"
        fi

        read -r -p "Pulsa Enter para continuar"
        clear
        show_header "Cabeceras HTTP de Seguridad 🔒" "Análisis de headers en sitios web"
    done
}

main "$@"
