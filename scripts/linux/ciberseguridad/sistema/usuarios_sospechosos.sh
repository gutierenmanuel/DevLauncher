#!/bin/bash
# Script: Revisión de usuarios sospechosos del sistema
# Detecta UIDs 0 extras, shells válidas, grupos privilegiados y sesiones activas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

VALID_SHELLS=("/bin/bash" "/bin/sh" "/bin/zsh" "/bin/fish" "/usr/bin/bash" "/usr/bin/zsh" "/usr/bin/fish")
PRIVILEGED_GROUPS=("sudo" "wheel" "docker" "adm" "lxd" "libvirt" "kvm" "disk" "shadow")
SYSTEM_USERS_MAX_UID=999

is_valid_shell() {
    local shell="$1"
    for s in "${VALID_SHELLS[@]}"; do
        [[ "$shell" == "$s" ]] && return 0
    done
    return 1
}

is_system_user() {
    local uid="$1"
    [[ "$uid" -le $SYSTEM_USERS_MAX_UID ]]
}

is_unusual_home() {
    local home="$1"
    local user="$2"
    # Inusual si no está en /home, /root, /var o /srv
    [[ ! "$home" =~ ^(/home|/root|/var|/srv|/nonexistent|/tmp) ]]
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

show_uid0_users() {
    echo -e "${PURPLE}════════ Usuarios con UID 0 (root) ═════════════${NC}"
    echo ""

    local found=0
    while IFS=: read -r username _ uid _; do
        if [[ "$uid" -eq 0 ]]; then
            if [[ "$username" == "root" ]]; then
                echo -e "  ${GREEN}${CHECKMARK}${NC} root (esperado)"
            else
                echo -e "  ${RED}${CROSS}${NC} ${BOLD}${username}${NC} tiene UID 0 ${RED}— SOSPECHOSO${NC}"
            fi
            found=$((found + 1))
        fi
    done < /etc/passwd

    if [[ $found -eq 1 ]]; then
        echo ""
        success "Solo root tiene UID 0"
    fi

    echo ""
}

show_users_with_shell() {
    echo -e "${PURPLE}════════ Usuarios con shell de login válida ═════${NC}"
    echo ""
    echo -e "  ${GRAY}(excluye usuarios de sistema con UID <= ${SYSTEM_USERS_MAX_UID})${NC}"
    echo ""

    local found=0
    while IFS=: read -r username _ uid _ _ home shell; do
        if ! is_system_user "$uid" && is_valid_shell "$shell"; then
            echo -e "  ${CYAN}${BULLET}${NC} ${BOLD}${username}${NC} (UID ${uid}) — shell: ${shell} — home: ${home}"
            found=$((found + 1))
        fi
    done < /etc/passwd

    [[ $found -eq 0 ]] && info "No se encontraron usuarios normales con shell válida"
    echo ""
}

show_unusual_homes() {
    echo -e "${PURPLE}════════ Usuarios con home inusual ══════════════${NC}"
    echo ""

    local found=0
    while IFS=: read -r username _ uid _ _ home shell; do
        if is_valid_shell "$shell" && is_unusual_home "$home" "$username"; then
            echo -e "  ${YELLOW}${WARNING}${NC} ${BOLD}${username}${NC} — home: ${home}"
            found=$((found + 1))
        fi
    done < /etc/passwd

    [[ $found -eq 0 ]] && success "No se detectaron homes en rutas inusuales"
    echo ""
}

show_privileged_groups() {
    echo -e "${PURPLE}════════ Grupos privilegiados y sus miembros ════${NC}"
    echo ""

    for group in "${PRIVILEGED_GROUPS[@]}"; do
        local members
        members="$(getent group "$group" 2>/dev/null | cut -d: -f4 || true)"
        if [[ -n "$members" ]]; then
            echo -e "  ${YELLOW}${BULLET}${NC} ${BOLD}${group}${NC}: ${members}"
        fi
    done

    echo ""
}

show_last_logins() {
    echo -e "${PURPLE}════════ Últimos logins por usuario ═════════════${NC}"
    echo ""

    if command -v lastlog &>/dev/null; then
        lastlog 2>/dev/null | awk 'NR==1 || $2 != "**Never" {
            if (NR==1) { printf "  %-16s %-10s %s\n", $1, $2, $NF }
            else if ($NF != "logged") { printf "  %-16s %-10s %s\n", $1, $2, $NF }
        }' | grep -v "^$" | while IFS= read -r line; do
            echo -e "  ${DIM_GRAY}${line}${NC}"
        done
    else
        warning "lastlog no disponible"
    fi

    echo ""
}

show_active_sessions() {
    echo -e "${PURPLE}════════ Sesiones activas ═══════════════════════${NC}"
    echo ""

    w 2>/dev/null | while IFS= read -r line; do
        echo -e "  ${DIM_GRAY}${line}${NC}"
    done

    echo ""
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    show_header "Usuarios Sospechosos 👥" "Revisión de cuentas y accesos del sistema"

    show_uid0_users
    show_users_with_shell
    show_unusual_homes
    show_privileged_groups
    show_last_logins
    show_active_sessions

    read -r -p "Pulsa Enter para continuar"
}

main "$@"
