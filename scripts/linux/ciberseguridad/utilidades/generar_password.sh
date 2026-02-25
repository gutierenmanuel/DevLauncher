#!/bin/bash
# Script: Generador de contraseñas seguras
# Varios modos: alfanumérico+símbolos, solo alfanumérico, passphrase y PIN

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Constantes ───────────────────────────────────────────────────────────────

DEFAULT_LENGTH=24
DEFAULT_COUNT=5
WORDLIST_PATHS=("/usr/share/dict/words" "/usr/dict/words" "/usr/share/dict/american-english")

# ─── Funciones puras ──────────────────────────────────────────────────────────

find_wordlist() {
    for path in "${WORDLIST_PATHS[@]}"; do
        [[ -f "$path" ]] && echo "$path" && return
    done
    echo ""
}

# Calcula entropía en bits: log2(charset^length)
calc_entropy() {
    local charset_size="$1"
    local length="$2"
    python3 -c "import math; print(f'{math.log2(${charset_size}**${length}):.1f}')" 2>/dev/null || echo "?"
}

# ─── Funciones de generación (middleware) ─────────────────────────────────────

gen_full() {
    local length="$1"
    # Alfanumérico + símbolos (excluye ambiguos: 0OlI1)
    tr -dc 'A-HJ-NP-Za-km-z2-9!@#$%^&*()_+-=[]{}|;:,.<>?' \
        < /dev/urandom | head -c "$length"
    echo
}

gen_alphanum() {
    local length="$1"
    tr -dc 'A-HJ-NP-Za-km-z2-9' \
        < /dev/urandom | head -c "$length"
    echo
}

gen_passphrase() {
    local words="$1"
    local wordlist
    wordlist="$(find_wordlist)"

    if [[ -z "$wordlist" ]]; then
        error "No se encontró diccionario en el sistema"
        info "Instálalo con: sudo apt install wamerican"
        return 1
    fi

    local phrase=""
    for ((i=0; i<words; i++)); do
        local word
        word="$(shuf -n1 "$wordlist" | tr -dc 'a-z' | head -c 20)"
        [[ ${#word} -lt 3 ]] && { i=$((i-1)); continue; }
        phrase="${phrase}${word}-"
    done
    echo "${phrase%-}"
}

gen_pin() {
    local length="$1"
    tr -dc '0-9' < /dev/urandom | head -c "$length"
    echo
}

# ─── Funciones de presentación ────────────────────────────────────────────────

show_passwords() {
    local mode="$1"
    local length="$2"
    local count="$3"

    echo ""
    local charset_size entropy

    case "$mode" in
        full)
            charset_size=78
            entropy="$(calc_entropy $charset_size "$length")"
            progress "Contraseñas alfanuméricas + símbolos (longitud: ${length}, entropía: ~${entropy} bits)"
            echo ""
            for ((i=1; i<=count; i++)); do
                echo -e "  ${GREEN}${i}.${NC} $(gen_full "$length")"
            done
            ;;
        alpha)
            charset_size=56
            entropy="$(calc_entropy $charset_size "$length")"
            progress "Contraseñas alfanuméricas (longitud: ${length}, entropía: ~${entropy} bits)"
            echo ""
            for ((i=1; i<=count; i++)); do
                echo -e "  ${GREEN}${i}.${NC} $(gen_alphanum "$length")"
            done
            ;;
        passphrase)
            progress "Passphrases (${length} palabras)"
            echo ""
            for ((i=1; i<=count; i++)); do
                echo -e "  ${GREEN}${i}.${NC} $(gen_passphrase "$length")"
            done
            ;;
        pin)
            charset_size=10
            entropy="$(calc_entropy $charset_size "$length")"
            progress "PINs numéricos (longitud: ${length}, entropía: ~${entropy} bits)"
            echo ""
            for ((i=1; i<=count; i++)); do
                echo -e "  ${GREEN}${i}.${NC} $(gen_pin "$length")"
            done
            ;;
    esac

    echo ""
    echo -e "  ${DIM_GRAY}Las contraseñas no se guardan en disco ni en el historial.${NC}"
}

ask_length() {
    local default="$1"
    local label="$2"
    read -r -p "$(echo -e "${CYAN}${label} [${default}]: ${NC}")" val
    echo "${val:-$default}"
}

show_menu() {
    clear
    show_header "Generador de Contraseñas 🔑" "Contraseñas seguras con entropía calculada"
    echo -e "  ${GREEN}1.${NC} Alfanumérico + símbolos ${DIM_GRAY}(recomendado)${NC}"
    echo -e "  ${GREEN}2.${NC} Solo alfanumérico ${DIM_GRAY}(compatible con sistemas restrictivos)${NC}"
    echo -e "  ${GREEN}3.${NC} Passphrase de palabras ${DIM_GRAY}(fácil de recordar)${NC}"
    echo -e "  ${GREEN}4.${NC} PIN numérico"
    echo -e "  ${GREEN}0.${NC} Salir"
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

        local length count

        case "$opcion" in
            0) info "Hasta luego"; exit 0 ;;
            1)
                length="$(ask_length $DEFAULT_LENGTH "Longitud")"
                count="$(ask_length $DEFAULT_COUNT "Cuántas generar")"
                show_passwords "full" "$length" "$count"
                ;;
            2)
                length="$(ask_length $DEFAULT_LENGTH "Longitud")"
                count="$(ask_length $DEFAULT_COUNT "Cuántas generar")"
                show_passwords "alpha" "$length" "$count"
                ;;
            3)
                length="$(ask_length 5 "Número de palabras")"
                count="$(ask_length $DEFAULT_COUNT "Cuántas generar")"
                show_passwords "passphrase" "$length" "$count"
                ;;
            4)
                length="$(ask_length 8 "Longitud del PIN")"
                count="$(ask_length $DEFAULT_COUNT "Cuántas generar")"
                show_passwords "pin" "$length" "$count"
                ;;
            *)
                warning "Opción inválida"
                ;;
        esac

        read -r -p "Pulsa Enter para continuar"
    done
}

main "$@"
