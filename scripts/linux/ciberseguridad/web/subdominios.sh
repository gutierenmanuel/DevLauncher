#!/bin/bash
# Script: Enumeración básica de subdominios por diccionario DNS
# Prueba subdominios comunes y muestra los que resuelven con su IP

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Diccionario integrado ─────────────────────────────────────────────────────

SUBDOMAIN_WORDLIST=(
    www mail ftp api dev admin vpn ssh git gitlab github jenkins ci cd
    staging prod test demo beta alpha app web portal intranet extranet
    remote desktop files cdn static assets media img images upload
    db database mysql postgres redis mongo smtp pop imap webmail mx
    ns1 ns2 dns autodiscover autoconfig crm erp shop store payment
    backup old legacy v1 v2 v3 internal corp office support helpdesk
    wiki docs doc status monitor grafana kibana elastic search
    registry docker k8s kubernetes auth sso login oauth api2 mobile
)

# ─── Funciones puras ──────────────────────────────────────────────────────────

is_valid_domain() {
    [[ -n "$1" && "$1" =~ ^[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$ ]]
}

build_fqdn() {
    local sub="$1"
    local domain="$2"
    echo "${sub}.${domain}"
}

build_output_path() {
    local domain="$1"
    local safe="${domain//./_}"
    echo "/tmp/subdominios_${safe}_$(date +%Y%m%d_%H%M%S).txt"
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

resolve_fqdn() {
    local fqdn="$1"
    dig +short A "$fqdn" 2>/dev/null | grep -E '^[0-9]+\.' | head -1 || true
}

resolve_cname() {
    local fqdn="$1"
    dig +short CNAME "$fqdn" 2>/dev/null | head -1 || true
}

scan_subdomains() {
    local domain="$1"
    local out_file="$2"
    local total="${#SUBDOMAIN_WORDLIST[@]}"
    local found=0
    local checked=0

    echo ""
    progress "Probando ${total} subdominios en ${BOLD}${domain}${NC}..."
    echo ""

    [[ -n "$out_file" ]] && echo "# Subdominios encontrados en ${domain} — $(date)" > "$out_file"

    for sub in "${SUBDOMAIN_WORDLIST[@]}"; do
        local fqdn
        fqdn="$(build_fqdn "$sub" "$domain")"
        checked=$((checked + 1))

        local ip
        ip="$(resolve_fqdn "$fqdn")"

        if [[ -n "$ip" ]]; then
            echo -e "  ${GREEN}${CHECKMARK}${NC} ${BOLD}${fqdn}${NC} → ${CYAN}${ip}${NC}"
            [[ -n "$out_file" ]] && echo "${fqdn} -> ${ip}" >> "$out_file"
            found=$((found + 1))
        else
            local cname
            cname="$(resolve_cname "$fqdn")"
            if [[ -n "$cname" ]]; then
                echo -e "  ${YELLOW}${BULLET}${NC} ${BOLD}${fqdn}${NC} → CNAME: ${cname}"
                [[ -n "$out_file" ]] && echo "${fqdn} -> CNAME: ${cname}" >> "$out_file"
                found=$((found + 1))
            fi
        fi

        # Progreso cada 20 subdominios
        if (( checked % 20 == 0 )); then
            echo -e "  ${DIM_GRAY}[${checked}/${total} probados, ${found} encontrados]${NC}"
        fi
    done

    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"

    if [[ $found -eq 0 ]]; then
        info "No se encontraron subdominios en el diccionario"
    else
        success "Total encontrados: ${BOLD}${found}${NC} de ${total} probados"
        [[ -n "$out_file" ]] && info "Resultado guardado en: ${out_file}"
    fi

    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
}

ask_save_output() {
    echo ""
    confirm "¿Guardar resultado en /tmp?" "y"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Enumeración de Subdominios 🕵️" "Diccionario DNS sobre un dominio objetivo"

    check_command "dig" "DIG_NOT_FOUND" || {
        handle_error "DIG_NOT_FOUND" "dig no está instalado" \
            "Instálalo con: sudo apt install dnsutils"
        exit 1
    }

    while true; do
        echo ""
        read -r -p "$(echo -e "${CYAN}Dominio a analizar (0 para salir): ${NC}")" domain
        [[ "$domain" == "0" || -z "$domain" ]] && { info "Hasta luego"; exit 0; }

        if ! is_valid_domain "$domain"; then
            warning "Dominio no válido: '${domain}'"
            read -r -p "Pulsa Enter para continuar"
            continue
        fi

        local out_file=""
        if ask_save_output; then
            out_file="$(build_output_path "$domain")"
        fi

        scan_subdomains "$domain" "$out_file"

        echo ""
        read -r -p "Pulsa Enter para continuar"
        clear
        show_header "Enumeración de Subdominios 🕵️" "Diccionario DNS sobre un dominio objetivo"
    done
}

main "$@"
