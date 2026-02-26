#!/usr/bin/env bash
# Script: Conversores de texto (mayúsculas, minúsculas, LF/CRLF) sobre un archivo o por extensión.

set -euo pipefail

OUTPUT_DIR="output_conv"

pause_and_exit() {
    local code="${1:-0}"
    read -r -p "Pulsa Enter para continuar"
    exit "$code"
}

normalize_extension() {
    local ext="$1"
    ext="${ext#.}"
    printf "%s" "$ext"
}

select_operation() {
    echo ""
    echo "Selecciona conversor:"
    echo "1) Convertir contenido a MAYÚSCULAS"
    echo "2) Convertir contenido a minúsculas"
    echo "3) Normalizar saltos de línea a LF"
    echo "4) Normalizar saltos de línea a CRLF"

    local option
    read -r -p "Opción: " option

    case "$option" in
        1) echo "upper" ;;
        2) echo "lower" ;;
        3) echo "lf" ;;
        4) echo "crlf" ;;
        *)
            echo "Opción inválida" >&2
            return 1
            ;;
    esac
}

select_mode() {
    echo ""
    echo "Aplicar sobre:"
    echo "1) Un archivo"
    echo "2) Todos los archivos del mismo tipo (extensión)"

    local option
    read -r -p "Opción: " option

    case "$option" in
        1) echo "single" ;;
        2) echo "all" ;;
        *)
            echo "Opción inválida" >&2
            return 1
            ;;
    esac
}

convert_file() {
    local input_file="$1"
    local operation="$2"

    local base_name file_name out_file
    file_name="$(basename "$input_file")"
    base_name="${file_name%.*}"

    local extension=""
    if [[ "$file_name" == *.* ]]; then
        extension=".${file_name##*.}"
    fi

    out_file="$OUTPUT_DIR/${base_name}_${operation}${extension}"

    case "$operation" in
        upper)
            awk '{ print toupper($0) }' "$input_file" > "$out_file"
            ;;
        lower)
            awk '{ print tolower($0) }' "$input_file" > "$out_file"
            ;;
        lf)
            sed 's/\r$//' "$input_file" > "$out_file"
            ;;
        crlf)
            sed 's/\r$//' "$input_file" | sed 's/$/\r/' > "$out_file"
            ;;
        *)
            echo "Conversor no soportado: $operation" >&2
            return 1
            ;;
    esac

    echo "✓ Convertido: $file_name -> $out_file"
}

main() {
    mkdir -p "$OUTPUT_DIR"

    local operation
    operation="$(select_operation)" || pause_and_exit 1

    local mode
    mode="$(select_mode)" || pause_and_exit 1

    if [[ "$mode" == "single" ]]; then
        local file_path
        read -r -p "Ruta del archivo a convertir: " file_path

        if [[ ! -f "$file_path" ]]; then
            echo "No existe el archivo: $file_path" >&2
            pause_and_exit 1
        fi

        convert_file "$file_path" "$operation" || pause_and_exit 1
        echo "Salida en: $OUTPUT_DIR"
        pause_and_exit 0
    fi

    local extension
    read -r -p "Extensión a procesar (ej: txt, md, json): " extension
    extension="$(normalize_extension "$extension")"

    if [[ -z "$extension" ]]; then
        echo "Debes indicar una extensión válida." >&2
        pause_and_exit 1
    fi

    mapfile -t files < <(find . -maxdepth 1 -type f -name "*.${extension}" -print)

    if [[ "${#files[@]}" -eq 0 ]]; then
        echo "No se encontraron archivos .${extension} en la carpeta actual." >&2
        pause_and_exit 1
    fi

    for file in "${files[@]}"; do
        local clean_path="${file#./}"
        convert_file "$clean_path" "$operation" || pause_and_exit 1
    done

    echo ""
    echo "Conversión finalizada. Archivos generados en: $OUTPUT_DIR"
    pause_and_exit 0
}

main "$@"
