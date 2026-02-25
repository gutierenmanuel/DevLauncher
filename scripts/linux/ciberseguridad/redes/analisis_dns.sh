#!/bin/bash
# Script: Análisis DNS completo de un dominio
# Consulta registros DNS, whois y comprobación básica de listas negras

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_valid_domain() {
    local domain="$1"
    [[ -n "$domain" && "$domain" =~ ^[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$ ]]
}

# Construye el nombre de consulta DNSBL: invierte la IP y añade el sufijo bl
build_dnsbl_query() {
    local ip="$1"
    local bl="$2"
    local reversed
    reversed="$(echo "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')"
    echo "${reversed}.${bl}"
}

record_label() {
    local type="$1"
    echo -e "${CYAN}── ${type} ──────────────────${NC}"
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

query_record() {
    local domain="$1"
    local type="$2"
    local result
    result="$(dig +short "$type" "$domain" 2>/dev/null || true)"
    if [[ -z "$result" ]]; then
        echo -e "  ${GRAY}(sin registros)${NC}"
    else
        echo "$result" | while IFS= read -r line; do
            echo -e "  ${GREEN}${BULLET}${NC} $line"
        done
    fi
}

show_all_records() {
    local domain="$1"
    echo ""

    for type in A AAAA MX NS TXT CNAME SOA; do
        record_label "$type"
        query_record "$domain" "$type"
        echo ""
    done
}

show_whois() {
    local domain="$1"
    echo ""
    progress "Consultando whois de ${domain}..."
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    whois "$domain" 2>/dev/null \
        | grep -iE "(registrar|registrant|creation|expiry|expire|updated|name server|status)" \
        | head -20 \
        | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
}

check_dnsbl() {
    local domain="$1"
    local ip
    ip="$(dig +short A "$domain" 2>/dev/null | head -1 || true)"

    if [[ -z "$ip" ]]; then
        warning "No se pudo resolver la IP de $domain para comprobar DNSBL"
        return
    fi

    info "IP a comprobar: $ip"
    echo ""

    local blacklists=(
        "zen.spamhaus.org"
        "bl.spamcop.net"
        "dnsbl.sorbs.net"
        "b.barracudacentral.org"
    )

    local found=0
    for bl in "${blacklists[@]}"; do
        local query
        query="$(build_dnsbl_query "$ip" "$bl")"
        local result
        result="$(dig +short A "$query" 2>/dev/null || true)"
        if [[ -n "$result" ]]; then
            echo -e "  ${RED}${CROSS}${NC} ${BOLD}${bl}${NC} → ${RED}LISTADO${NC} ($result)"
            found=$((found + 1))
        else
            echo -e "  ${GREEN}${CHECKMARK}${NC} ${bl} → limpio"
        fi
    done

    echo ""
    if [[ $found -eq 0 ]]; then
        success "La IP no aparece en ninguna lista negra comprobada"
    else
        warning "La IP aparece en ${found} lista(s) negra(s)"
    fi
}

show_menu() {
    clear
    show_header "Análisis DNS 🔎" "Registros, whois y listas negras"
    echo -e "  ${GREEN}1.${NC} Consultar todos los registros DNS"
    echo -e "  ${GREEN}2.${NC} Whois del dominio"
    echo -e "  ${GREEN}3.${NC} Comprobar listas negras (DNSBL)"
    echo -e "  ${GREEN}4.${NC} Análisis completo (todo lo anterior)"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -n "  Opción: "
}

ask_domain() {
    echo ""
    read -r -p "$(echo -e "${CYAN}Dominio a analizar: ${NC}")" domain
    echo "$domain"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Análisis DNS 🔎" "Registros, whois y listas negras"

    check_command "dig" "DIG_NOT_FOUND" || {
        handle_error "DIG_NOT_FOUND" "dig no está instalado" \
            "Instálalo con: sudo apt install dnsutils"
        exit 1
    }

    while true; do
        show_menu
        read -r opcion
        [[ "$opcion" == "0" ]] && { info "Hasta luego"; exit 0; }

        local domain
        domain="$(ask_domain)"

        if ! is_valid_domain "$domain"; then
            warning "Dominio no válido: '$domain'"
            read -r -p "Pulsa Enter para continuar"
            continue
        fi

        info "Analizando: ${BOLD}${domain}${NC}"

        case "$opcion" in
            1)
                show_all_records "$domain"
                ;;
            2)
                check_command "whois" "WHOIS_NOT_FOUND" || {
                    warning "whois no está instalado. Instálalo con: sudo apt install whois"
                    read -r -p "Pulsa Enter"; continue
                }
                show_whois "$domain"
                ;;
            3)
                check_dnsbl "$domain"
                ;;
            4)
                show_all_records "$domain"
                if command -v whois &>/dev/null; then
                    show_whois "$domain"
                else
                    warning "whois no disponible, omitiendo"
                fi
                echo ""
                check_dnsbl "$domain"
                ;;
            *)
                warning "Opción inválida"
                ;;
        esac

        echo ""
        read -r -p "Pulsa Enter para continuar"
    done
}

main "$@"
