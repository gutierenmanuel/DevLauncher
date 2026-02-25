#!/bin/bash
# Script: Auditoría de configuración SSH
# Analiza sshd_config, logins fallidos y claves autorizadas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Constantes ───────────────────────────────────────────────────────────────

SSHD_CONFIG="/etc/ssh/sshd_config"

# ─── Funciones puras ──────────────────────────────────────────────────────────

get_sshd_value() {
    local config="$1"
    local key="$2"
    grep -iE "^[[:space:]]*${key}[[:space:]]" "$config" 2>/dev/null \
        | tail -1 | awk '{print $2}' | xargs
}

severity_ok()   { echo -e "  ${GREEN}${CHECKMARK}${NC}"; }
severity_warn() { echo -e "  ${YELLOW}${WARNING}${NC}"; }
severity_bad()  { echo -e "  ${RED}${CROSS}${NC}"; }

evaluate_permit_root() {
    local val="${1:-yes}"
    case "${val,,}" in
        no|prohibit-password) echo "ok" ;;
        without-password)     echo "warn" ;;
        *)                    echo "bad" ;;
    esac
}

evaluate_password_auth() {
    local val="${1:-yes}"
    [[ "${val,,}" == "no" ]] && echo "ok" || echo "bad"
}

evaluate_max_auth_tries() {
    local val="${1:-6}"
    [[ "$val" -le 3 ]] && echo "ok" || echo "warn"
}

evaluate_x11_forwarding() {
    local val="${1:-no}"
    [[ "${val,,}" == "no" ]] && echo "ok" || echo "warn"
}

# ─── Funciones de presentación ────────────────────────────────────────────────

print_check() {
    local level="$1"
    local label="$2"
    local value="$3"
    local note="$4"

    case "$level" in
        ok)   echo -e "  ${GREEN}${CHECKMARK}${NC} ${BOLD}${label}${NC}: ${value}" ;;
        warn) echo -e "  ${YELLOW}${WARNING}${NC} ${BOLD}${label}${NC}: ${value} ${DIM_GRAY}— ${note}${NC}" ;;
        bad)  echo -e "  ${RED}${CROSS}${NC} ${BOLD}${label}${NC}: ${value} ${DIM_GRAY}— ${note}${NC}" ;;
    esac
}

show_sshd_checks() {
    local config="$1"

    echo -e "${PURPLE}════════ Configuración sshd_config ════════════${NC}"
    echo ""

    # PermitRootLogin
    local permit_root
    permit_root="$(get_sshd_value "$config" "PermitRootLogin")"
    permit_root="${permit_root:-yes (por defecto)}"
    print_check "$(evaluate_permit_root "$permit_root")" \
        "PermitRootLogin" "$permit_root" "debería ser 'no' o 'prohibit-password'"

    # PasswordAuthentication
    local pass_auth
    pass_auth="$(get_sshd_value "$config" "PasswordAuthentication")"
    pass_auth="${pass_auth:-yes (por defecto)}"
    print_check "$(evaluate_password_auth "$pass_auth")" \
        "PasswordAuthentication" "$pass_auth" "debería ser 'no' (usar claves)"

    # Port
    local port
    port="$(get_sshd_value "$config" "Port")"
    port="${port:-22 (por defecto)}"
    if [[ "$port" == "22"* ]]; then
        print_check "warn" "Port" "$port" "considera cambiar el puerto 22"
    else
        print_check "ok" "Port" "$port"
    fi

    # MaxAuthTries
    local max_tries
    max_tries="$(get_sshd_value "$config" "MaxAuthTries")"
    max_tries="${max_tries:-6 (por defecto)}"
    print_check "$(evaluate_max_auth_tries "${max_tries%% *}")" \
        "MaxAuthTries" "$max_tries" "recomendado <= 3"

    # X11Forwarding
    local x11
    x11="$(get_sshd_value "$config" "X11Forwarding")"
    x11="${x11:-no (por defecto)}"
    print_check "$(evaluate_x11_forwarding "$x11")" \
        "X11Forwarding" "$x11" "deshabilitar si no se usa"

    # AllowUsers / AllowGroups
    local allow_users allow_groups
    allow_users="$(get_sshd_value "$config" "AllowUsers")"
    allow_groups="$(get_sshd_value "$config" "AllowGroups")"
    if [[ -z "$allow_users" && -z "$allow_groups" ]]; then
        print_check "warn" "AllowUsers/AllowGroups" "(no definidos)" "considera restringir acceso por usuario o grupo"
    else
        [[ -n "$allow_users"  ]] && print_check "ok" "AllowUsers"  "$allow_users"
        [[ -n "$allow_groups" ]] && print_check "ok" "AllowGroups" "$allow_groups"
    fi

    echo ""
}

show_failed_logins() {
    echo -e "${PURPLE}════════ Últimos intentos de login fallidos ════${NC}"
    echo ""

    if command -v journalctl &>/dev/null; then
        journalctl -u ssh -u sshd --no-pager -q 2>/dev/null \
            | grep -i "failed\|invalid\|error" | tail -10 \
            | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done || true
    elif [[ -f /var/log/auth.log ]]; then
        grep -i "failed\|invalid" /var/log/auth.log 2>/dev/null | tail -10 \
            | while IFS= read -r line; do echo -e "  ${DIM_GRAY}${line}${NC}"; done || true
    else
        info "No se encontró fuente de logs de autenticación"
    fi

    echo ""
}

show_authorized_keys() {
    echo -e "${PURPLE}════════ Claves autorizadas (~/.ssh) ═══════════${NC}"
    echo ""

    local auth_keys="$HOME/.ssh/authorized_keys"
    if [[ -f "$auth_keys" ]]; then
        local count
        count="$(wc -l < "$auth_keys")"
        info "${count} clave(s) en authorized_keys:"
        while IFS= read -r line; do
            [[ -z "$line" || "$line" == "#"* ]] && continue
            local key_type key_comment
            key_type="$(echo "$line" | awk '{print $1}')"
            key_comment="$(echo "$line" | awk '{print $NF}')"
            echo -e "  ${GREEN}${BULLET}${NC} ${key_type} ${DIM_GRAY}— ${key_comment}${NC}"
        done < "$auth_keys"
    else
        info "No existe $auth_keys"
    fi

    echo ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Auditoría SSH 🔑" "Revisión de configuración y accesos"

    if [[ ! -f "$SSHD_CONFIG" ]]; then
        warning "No se encontró $SSHD_CONFIG — ¿está instalado sshd?"
    else
        show_sshd_checks "$SSHD_CONFIG"
    fi

    show_failed_logins
    show_authorized_keys

    read -r -p "Pulsa Enter para continuar"
}

main "$@"
