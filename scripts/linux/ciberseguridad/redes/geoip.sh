#!/bin/bash
# Script: Geolocalización de IP o dominio
# Muestra país, ciudad, ISP, ASN y detecta VPN/Proxy/Tor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Constantes ───────────────────────────────────────────────────────────────

GEOIP_API="http://ip-api.com/json"
GEOIP_FIELDS="status,message,country,countryCode,regionName,city,zip,lat,lon,isp,org,as,proxy,hosting,query"

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_ip() {
    [[ "$1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

is_valid_target() {
    [[ -n "$1" ]]
}

build_api_url() {
    local target="$1"
    echo "${GEOIP_API}/${target}?fields=${GEOIP_FIELDS}"
}

extract_field() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"${key}\":[^,}]*" | cut -d: -f2- | tr -d '"' | xargs
}

flag_emoji() {
    local code="${1^^}"
    # Convierte código de país en emoji de bandera (Unicode regional indicators)
    python3 -c "
code = '${code}'
if len(code) == 2:
    flag = chr(0x1F1E0 + ord(code[0]) - ord('A')) + chr(0x1F1E0 + ord(code[1]) - ord('A'))
    print(flag)
else:
    print('')
" 2>/dev/null || echo ""
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

resolve_domain_to_ip() {
    local domain="$1"
    dig +short A "$domain" 2>/dev/null | head -1 || true
}

fetch_geoip() {
    local target="$1"
    local url
    url="$(build_api_url "$target")"
    curl -s --max-time 10 "$url" 2>/dev/null
}

display_result() {
    local json="$1"

    local status country country_code region city zip lat lon isp org asn proxy hosting ip_queried

    status="$(extract_field "$json" "status")"
    if [[ "$status" != "success" ]]; then
        local msg
        msg="$(extract_field "$json" "message")"
        error "La API devolvió error: ${msg:-respuesta inesperada}"
        return 1
    fi

    ip_queried="$(extract_field "$json" "query")"
    country="$(extract_field "$json" "country")"
    country_code="$(extract_field "$json" "countryCode")"
    region="$(extract_field "$json" "regionName")"
    city="$(extract_field "$json" "city")"
    zip="$(extract_field "$json" "zip")"
    lat="$(extract_field "$json" "lat")"
    lon="$(extract_field "$json" "lon")"
    isp="$(extract_field "$json" "isp")"
    org="$(extract_field "$json" "org")"
    asn="$(extract_field "$json" "as")"
    proxy="$(extract_field "$json" "proxy")"
    hosting="$(extract_field "$json" "hosting")"

    local flag
    flag="$(flag_emoji "$country_code")"

    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}IP consultada:${NC}  ${BOLD}${ip_queried}${NC}"
    echo -e "  ${CYAN}País:${NC}           ${flag} ${country} (${country_code})"
    echo -e "  ${CYAN}Región:${NC}         ${region}"
    echo -e "  ${CYAN}Ciudad:${NC}         ${city} ${zip}"
    echo -e "  ${CYAN}Coordenadas:${NC}    ${lat}, ${lon}"
    echo -e "  ${CYAN}ISP:${NC}            ${isp}"
    echo -e "  ${CYAN}Organización:${NC}   ${org}"
    echo -e "  ${CYAN}ASN:${NC}            ${asn}"
    echo ""

    if [[ "$proxy" == "true" ]]; then
        echo -e "  ${RED}${WARNING} VPN / Proxy detectado${NC}"
    fi
    if [[ "$hosting" == "true" ]]; then
        echo -e "  ${YELLOW}${INFO} Hosting / datacenter detectado${NC}"
    fi
    if [[ "$proxy" != "true" && "$hosting" != "true" ]]; then
        echo -e "  ${GREEN}${CHECKMARK} Sin indicios de VPN, Proxy o Tor${NC}"
    fi

    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
}

lookup_my_ip() {
    progress "Obteniendo tu IP pública..."
    local my_ip
    my_ip="$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null || true)"
    if [[ -z "$my_ip" ]]; then
        error "No se pudo obtener la IP pública"
        return 1
    fi
    info "Tu IP pública: ${BOLD}${my_ip}${NC}"
    local json
    json="$(fetch_geoip "$my_ip")"
    display_result "$json"
}

lookup_target() {
    echo ""
    read -r -p "$(echo -e "${CYAN}IP o dominio a consultar: ${NC}")" target

    if ! is_valid_target "$target"; then
        warning "Introduce un objetivo válido"
        return
    fi

    local query_target="$target"

    if ! is_ip "$target"; then
        progress "Resolviendo dominio a IP..."
        local resolved
        resolved="$(resolve_domain_to_ip "$target")"
        if [[ -z "$resolved" ]]; then
            error "No se pudo resolver '$target'"
            return 1
        fi
        info "Resuelto: ${target} → ${BOLD}${resolved}${NC}"
        query_target="$resolved"
    fi

    progress "Consultando geolocalización de ${BOLD}${query_target}${NC}..."
    local json
    json="$(fetch_geoip "$query_target")"
    display_result "$json"
}

show_menu() {
    clear
    show_header "GeoIP 🌍" "Geolocalización de IPs y dominios"
    echo -e "  ${GREEN}1.${NC} Consultar mi IP pública"
    echo -e "  ${GREEN}2.${NC} Consultar IP o dominio"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -n "  Opción: "
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "GeoIP 🌍" "Geolocalización de IPs y dominios"

    check_command "curl" "CURL_NOT_FOUND" || {
        handle_error "CURL_NOT_FOUND" "curl no está instalado" \
            "Instálalo con: sudo apt install curl"
        exit 1
    }

    while true; do
        show_menu
        read -r opcion
        echo ""

        case "$opcion" in
            1) lookup_my_ip ;;
            2) lookup_target ;;
            0) info "Hasta luego"; exit 0 ;;
            *) warning "Opción inválida" ;;
        esac

        echo ""
        read -r -p "Pulsa Enter para continuar"
    done
}

main "$@"
