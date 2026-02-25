#!/bin/bash
# Script: Inspector de certificados SSL/TLS
# Muestra detalles del cert, validez, cadena de confianza y versión de TLS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Constantes ───────────────────────────────────────────────────────────────

WARN_DAYS=30

# ─── Funciones puras ──────────────────────────────────────────────────────────

parse_host_port() {
    local input="$1"
    # Separa host:puerto; por defecto puerto 443
    if [[ "$input" =~ ^(.+):([0-9]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        echo "${input} 443"
    fi
}

is_valid_host() {
    [[ -n "$1" ]]
}

days_until_expiry() {
    local expiry_str="$1"
    local expiry_epoch
    expiry_epoch="$(date -d "$expiry_str" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_str" +%s 2>/dev/null || echo 0)"
    local now_epoch
    now_epoch="$(date +%s)"
    echo $(( (expiry_epoch - now_epoch) / 86400 ))
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

fetch_cert_text() {
    local host="$1"
    local port="$2"
    echo | timeout 10 openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null \
        | openssl x509 -noout -text 2>/dev/null
}

fetch_cert_dates() {
    local host="$1"
    local port="$2"
    echo | timeout 10 openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null \
        | openssl x509 -noout -dates 2>/dev/null
}

fetch_cert_subject() {
    local host="$1"
    local port="$2"
    echo | timeout 10 openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null \
        | openssl x509 -noout -subject -issuer 2>/dev/null
}

fetch_cert_san() {
    local host="$1"
    local port="$2"
    echo | timeout 10 openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null \
        | openssl x509 -noout -ext subjectAltName 2>/dev/null \
        | grep -oE 'DNS:[^,]+' | sed 's/DNS://g' | tr '\n' '  '
}

fetch_chain() {
    local host="$1"
    local port="$2"
    echo | timeout 10 openssl s_client -connect "${host}:${port}" -servername "$host" \
        -showcerts 2>/dev/null \
        | grep -E "^(subject|issuer)=" | sed 's/^/    /'
}

check_tls_version() {
    local host="$1"
    local port="$2"
    local proto="$3"
    local label="$4"
    if echo | timeout 5 openssl s_client -connect "${host}:${port}" \
        -servername "$host" "${proto}" 2>/dev/null | grep -q "Cipher"; then
        echo -e "  ${RED}${CROSS}${NC} ${label} ${DIM_GRAY}— soportado (inseguro)${NC}"
    else
        echo -e "  ${GREEN}${CHECKMARK}${NC} ${label} no soportado"
    fi
}

show_cert_info() {
    local host="$1"
    local port="$2"

    progress "Conectando a ${BOLD}${host}:${port}${NC}..."
    echo ""

    # Sujeto e Issuer
    local subj_issuer
    subj_issuer="$(fetch_cert_subject "$host" "$port")"
    if [[ -z "$subj_issuer" ]]; then
        error "No se pudo obtener el certificado. ¿El host está disponible?"
        return 1
    fi

    local subject issuer
    subject="$(echo "$subj_issuer" | grep ^subject | cut -d= -f2- | xargs)"
    issuer="$(echo "$subj_issuer" | grep ^issuer  | cut -d= -f2- | xargs)"

    # Fechas
    local dates
    dates="$(fetch_cert_dates "$host" "$port")"
    local not_before not_after
    not_before="$(echo "$dates" | grep notBefore | cut -d= -f2)"
    not_after="$(echo "$dates"  | grep notAfter  | cut -d= -f2)"

    local days_left
    days_left="$(days_until_expiry "$not_after")"

    # SANs
    local sans
    sans="$(fetch_cert_san "$host" "$port")"

    echo -e "${PURPLE}════════ Certificado SSL/TLS ════════════════════${NC}"
    echo -e "  ${CYAN}Sujeto:${NC}     ${subject}"
    echo -e "  ${CYAN}Emisor:${NC}     ${issuer}"
    echo -e "  ${CYAN}Válido desde:${NC} ${not_before}"
    echo -e "  ${CYAN}Válido hasta:${NC} ${not_after}"
    echo ""

    if [[ $days_left -le 0 ]]; then
        echo -e "  ${RED}${CROSS} CERTIFICADO EXPIRADO${NC}"
    elif [[ $days_left -le $WARN_DAYS ]]; then
        echo -e "  ${YELLOW}${WARNING} Expira en ${BOLD}${days_left} días${NC} ${DIM_GRAY}— ¡renovar pronto!${NC}"
    else
        echo -e "  ${GREEN}${CHECKMARK} Válido — expira en ${BOLD}${days_left} días${NC}"
    fi

    echo ""
    echo -e "  ${CYAN}SANs:${NC}"
    echo "$sans" | tr ' ' '\n' | grep -v '^$' | while IFS= read -r san; do
        echo -e "    ${GREEN}${BULLET}${NC} ${san}"
    done

    echo ""
    echo -e "${PURPLE}════════ Cadena de confianza ════════════════════${NC}"
    fetch_chain "$host" "$port"

    echo ""
    echo -e "${PURPLE}════════ Versiones TLS aceptadas ════════════════${NC}"
    check_tls_version "$host" "$port" "-tls1"   "TLS 1.0"
    check_tls_version "$host" "$port" "-tls1_1" "TLS 1.1"
    echo -e "  ${GREEN}${CHECKMARK}${NC} TLS 1.2 / 1.3 ${DIM_GRAY}(estándar)${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════════${NC}"
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Certificado SSL/TLS 🔏" "Inspector de certificados y protocolo TLS"

    check_command "openssl" "OPENSSL_NOT_FOUND" || {
        handle_error "OPENSSL_NOT_FOUND" "openssl no está instalado" \
            "Instálalo con: sudo apt install openssl"
        exit 1
    }

    while true; do
        echo ""
        read -r -p "$(echo -e "${CYAN}Host a inspeccionar, ej: example.com o example.com:8443 (0 para salir): ${NC}")" input
        [[ "$input" == "0" || -z "$input" ]] && { info "Hasta luego"; exit 0; }

        read -r host port <<< "$(parse_host_port "$input")"

        if ! is_valid_host "$host"; then
            warning "Host no válido"
        else
            show_cert_info "$host" "$port"
        fi

        echo ""
        read -r -p "Pulsa Enter para continuar"
        clear
        show_header "Certificado SSL/TLS 🔏" "Inspector de certificados y protocolo TLS"
    done
}

main "$@"
