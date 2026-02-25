#!/bin/bash
# Script: Cifrar y descifrar archivos con AES-256
# Usa openssl AES-256-CBC con PBKDF2 para máxima compatibilidad

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

enc_output_path() {
    local input="$1"
    echo "${input}.enc"
}

dec_output_path() {
    local input="$1"
    # Quita .enc si termina en eso, sino añade .dec
    if [[ "$input" == *.enc ]]; then
        echo "${input%.enc}"
    else
        echo "${input}.dec"
    fi
}

human_size() {
    local file="$1"
    du -sh "$file" 2>/dev/null | cut -f1
}

passwords_match() {
    [[ "$1" == "$2" ]]
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

ask_password_confirm() {
    local pass1 pass2
    read -rsp "$(echo -e "${CYAN}Contraseña: ${NC}")" pass1; echo
    read -rsp "$(echo -e "${CYAN}Confirmar contraseña: ${NC}")" pass2; echo

    if ! passwords_match "$pass1" "$pass2"; then
        error "Las contraseñas no coinciden"
        return 1
    fi

    if [[ ${#pass1} -lt 8 ]]; then
        warning "La contraseña es muy corta (mínimo 8 caracteres recomendado)"
    fi

    echo "$pass1"
}

ask_password() {
    local pass
    read -rsp "$(echo -e "${CYAN}Contraseña: ${NC}")" pass; echo
    echo "$pass"
}

do_encrypt() {
    local input="$1"
    local output="$2"
    local password="$3"

    openssl enc -aes-256-cbc -pbkdf2 -iter 310000 \
        -in "$input" -out "$output" \
        -pass "pass:${password}" 2>/dev/null
}

do_decrypt() {
    local input="$1"
    local output="$2"
    local password="$3"

    openssl enc -d -aes-256-cbc -pbkdf2 -iter 310000 \
        -in "$input" -out "$output" \
        -pass "pass:${password}" 2>/dev/null
}

action_encrypt() {
    echo ""
    read -r -p "$(echo -e "${CYAN}Archivo a cifrar: ${NC}")" input

    if [[ ! -f "$input" ]]; then
        error "Archivo no encontrado: $input"
        return 1
    fi

    local output
    output="$(enc_output_path "$input")"

    if [[ -f "$output" ]]; then
        warning "Ya existe: $output"
        confirm "¿Sobrescribir?" "n" || return 0
    fi

    echo ""
    info "Archivo: ${BOLD}${input}${NC} ($(human_size "$input"))"
    info "Salida:  ${BOLD}${output}${NC}"
    echo ""
    echo -e "${DIM_GRAY}La contraseña NO se puede recuperar si se pierde.${NC}"
    echo ""

    local password
    password="$(ask_password_confirm)" || return 1

    echo ""
    progress "Cifrando con AES-256-CBC + PBKDF2..."

    if do_encrypt "$input" "$output" "$password"; then
        success "Archivo cifrado: ${BOLD}${output}${NC} ($(human_size "$output"))"
        echo ""
        if confirm "¿Eliminar el archivo original?" "n"; then
            rm -f "$input"
            info "Archivo original eliminado"
        fi
    else
        error "El cifrado falló"
        rm -f "$output"
        return 1
    fi

    # Limpiar variable de contraseña de memoria
    password=""
}

action_decrypt() {
    echo ""
    read -r -p "$(echo -e "${CYAN}Archivo a descifrar (.enc): ${NC}")" input

    if [[ ! -f "$input" ]]; then
        error "Archivo no encontrado: $input"
        return 1
    fi

    local output
    output="$(dec_output_path "$input")"

    if [[ -f "$output" ]]; then
        warning "Ya existe: $output"
        confirm "¿Sobrescribir?" "n" || return 0
    fi

    echo ""
    info "Archivo: ${BOLD}${input}${NC} ($(human_size "$input"))"
    info "Salida:  ${BOLD}${output}${NC}"
    echo ""

    local password
    password="$(ask_password)"

    echo ""
    progress "Descifrando..."

    if do_decrypt "$input" "$output" "$password"; then
        success "Archivo descifrado: ${BOLD}${output}${NC} ($(human_size "$output"))"
    else
        error "El descifrado falló — ¿contraseña incorrecta?"
        rm -f "$output"
        return 1
    fi

    password=""
}

show_menu() {
    clear
    show_header "Cifrado de Archivos 🔒" "AES-256-CBC con PBKDF2 — via openssl"
    echo -e "  ${GREEN}1.${NC} Cifrar archivo"
    echo -e "  ${GREEN}2.${NC} Descifrar archivo"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -e "  ${DIM_GRAY}Algoritmo: AES-256-CBC | Derivación: PBKDF2 (310.000 iteraciones)${NC}"
    echo ""
    echo -n "  Opción: "
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    check_command "openssl" "OPENSSL_NOT_FOUND" || {
        handle_error "OPENSSL_NOT_FOUND" "openssl no está instalado" \
            "Instálalo con: sudo apt install openssl"
        exit 1
    }

    while true; do
        show_menu
        read -r opcion
        echo ""

        case "$opcion" in
            0) info "Hasta luego"; exit 0 ;;
            1) action_encrypt ;;
            2) action_decrypt ;;
            *) warning "Opción inválida" ;;
        esac

        echo ""
        read -r -p "Pulsa Enter para continuar"
    done
}

main "$@"
