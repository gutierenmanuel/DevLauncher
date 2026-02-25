#!/bin/bash
# Script: Verificador de integridad de archivos por hash
# Calcula y compara MD5, SHA1, SHA256 y SHA512

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ─── Funciones puras ──────────────────────────────────────────────────────────

select_hash_cmd() {
    local algo="$1"
    case "$algo" in
        md5)    echo "md5sum" ;;
        sha1)   echo "sha1sum" ;;
        sha256) echo "sha256sum" ;;
        sha512) echo "sha512sum" ;;
        *)      echo "" ;;
    esac
}

algo_label() {
    local algo="$1"
    case "$algo" in
        md5)    echo "MD5    ${DIM_GRAY}(128 bits — no usar para seguridad)${NC}" ;;
        sha1)   echo "SHA1   ${DIM_GRAY}(160 bits — deprecado)${NC}" ;;
        sha256) echo "SHA256 ${DIM_GRAY}(256 bits — recomendado)${NC}" ;;
        sha512) echo "SHA512 ${DIM_GRAY}(512 bits — máxima integridad)${NC}" ;;
    esac
}

hashes_match() {
    local a="${1,,}"
    local b="${2,,}"
    [[ "$a" == "$b" ]]
}

# ─── Funciones de efecto ──────────────────────────────────────────────────────

compute_hash() {
    local cmd="$1"
    local file="$2"
    "$cmd" "$file" 2>/dev/null | awk '{print $1}'
}

check_single_file() {
    local file="$1"
    local algo="$2"

    local cmd
    cmd="$(select_hash_cmd "$algo")"

    if [[ -z "$cmd" ]]; then
        error "Algoritmo desconocido: $algo"
        return 1
    fi

    if ! command -v "$cmd" &>/dev/null; then
        error "$cmd no está disponible"
        return 1
    fi

    progress "Calculando ${algo^^} de: ${BOLD}$(basename "$file")${NC}"
    local hash
    hash="$(compute_hash "$cmd" "$file")"

    echo ""
    echo -e "  ${CYAN}Archivo:${NC} ${file}"
    echo -e "  ${CYAN}${algo^^}:${NC}    ${BOLD}${hash}${NC}"
    echo ""

    if confirm "¿Comparar contra un hash conocido?" "n"; then
        echo ""
        read -r -p "$(echo -e "${CYAN}Hash esperado: ${NC}")" expected
        echo ""

        if hashes_match "$hash" "$expected"; then
            echo -e "  ${GREEN}${CHECKMARK} COINCIDE${NC} — La integridad del archivo es correcta"
        else
            echo -e "  ${RED}${CROSS} NO COINCIDE${NC} — El archivo puede estar corrupto o modificado"
            echo ""
            echo -e "  ${CYAN}Calculado:${NC} ${hash}"
            echo -e "  ${CYAN}Esperado: ${NC} ${expected}"
        fi
    fi
}

check_directory() {
    local dir="$1"
    local algo="$2"

    local cmd
    cmd="$(select_hash_cmd "$algo")"

    progress "Calculando ${algo^^} de todos los archivos en: ${BOLD}${dir}${NC}"
    echo ""

    find "$dir" -maxdepth 1 -type f | sort | while IFS= read -r file; do
        local hash
        hash="$(compute_hash "$cmd" "$file")"
        echo -e "  ${GREEN}${BULLET}${NC} ${hash}  $(basename "$file")"
    done
}

ask_algo() {
    echo ""
    echo -e "  ${GREEN}1.${NC} $(algo_label md5)"
    echo -e "  ${GREEN}2.${NC} $(algo_label sha1)"
    echo -e "  ${GREEN}3.${NC} $(algo_label sha256)  ${DIM_GRAY}← recomendado${NC}"
    echo -e "  ${GREEN}4.${NC} $(algo_label sha512)"
    echo ""
    read -r -p "$(echo -e "${CYAN}Algoritmo [3]: ${NC}")" opt
    case "${opt:-3}" in
        1) echo "md5" ;;
        2) echo "sha1" ;;
        3) echo "sha256" ;;
        4) echo "sha512" ;;
        *) echo "sha256" ;;
    esac
}

show_menu() {
    clear
    show_header "Verificador de Hash 🧮" "Integridad de archivos con md5/sha256/sha512"
    echo -e "  ${GREEN}1.${NC} Calcular hash de un archivo"
    echo -e "  ${GREEN}2.${NC} Calcular hash de todos los archivos en un directorio"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
    echo -n "  Opción: "
}

# ─── Orquestación ─────────────────────────────────────────────────────────────

main() {
    while true; do
        show_menu
        read -r opcion
        echo ""

        case "$opcion" in
            0) info "Hasta luego"; exit 0 ;;
            1)
                read -r -p "$(echo -e "${CYAN}Ruta del archivo: ${NC}")" target
                if [[ ! -f "$target" ]]; then
                    error "Archivo no encontrado: $target"
                else
                    local algo
                    algo="$(ask_algo)"
                    check_single_file "$target" "$algo"
                fi
                ;;
            2)
                read -r -p "$(echo -e "${CYAN}Ruta del directorio: ${NC}")" target
                if [[ ! -d "$target" ]]; then
                    error "Directorio no encontrado: $target"
                else
                    local algo
                    algo="$(ask_algo)"
                    check_directory "$target" "$algo"
                fi
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
