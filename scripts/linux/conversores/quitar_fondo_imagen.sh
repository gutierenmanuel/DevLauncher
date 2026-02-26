#!/usr/bin/env bash
# Script: Elimina el fondo de imágenes por archivo o por lote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_TOOL="$SCRIPT_DIR/../../lib/remover_fondo.py"

pause_and_exit() {
    local code="${1:-0}"
    read -r -p "Pulsa Enter para continuar"
    exit "$code"
}

resolve_python() {
    if command -v python3 &>/dev/null; then
        echo "python3"
        return 0
    fi

    if command -v python &>/dev/null; then
        echo "python"
        return 0
    fi

    return 1
}

select_mode() {
    echo ""
    echo "Aplicar sobre:"
    echo "1) Un archivo"
    echo "2) Todos los archivos de una extensión"

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

main() {
    if [[ ! -f "$PY_TOOL" ]]; then
        echo "No se encontró el script de remover fondo: $PY_TOOL" >&2
        pause_and_exit 1
    fi

    local py_cmd
    py_cmd="$(resolve_python)" || {
        echo "No se encontró Python (python3/python) en el PATH." >&2
        pause_and_exit 1
    }

    local mode
    mode="$(select_mode)" || pause_and_exit 1

    local current_dir
    current_dir="$PWD"

    if [[ "$mode" == "single" ]]; then
        local file_path
        read -r -p "Ruta del archivo de imagen: " file_path

        "$py_cmd" "$PY_TOOL" \
            --mode "single" \
            --workdir "$current_dir" \
            --input "$file_path" || pause_and_exit 1

        pause_and_exit 0
    fi

    local filter_ext
    read -r -p "Extensión origen a procesar (ej: png, jpg, webp): " filter_ext

    "$py_cmd" "$PY_TOOL" \
        --mode "all" \
        --workdir "$current_dir" \
        --filter-ext "$filter_ext" || pause_and_exit 1

    pause_and_exit 0
}

main "$@"
