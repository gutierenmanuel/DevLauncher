#!/usr/bin/env bash
# Script: Conversor de audio por archivo o por lote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_TOOL="$SCRIPT_DIR/../../lib/media_conversor.py"

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

select_target_ext() {
    echo ""
    echo "Formato de salida de audio (ej: mp3, wav, flac, aac, ogg, m4a):"

    local ext
    read -r -p "Extensión destino: " ext
    ext="${ext#.}"

    if [[ -z "$ext" ]]; then
        echo "Debes indicar una extensión válida." >&2
        return 1
    fi

    echo "$ext"
}

main() {
    if [[ ! -f "$PY_TOOL" ]]; then
        echo "No se encontró el motor multimedia: $PY_TOOL" >&2
        pause_and_exit 1
    fi

    local py_cmd
    py_cmd="$(resolve_python)" || {
        echo "No se encontró Python (python3/python) en el PATH." >&2
        pause_and_exit 1
    }

    local mode
    mode="$(select_mode)" || pause_and_exit 1

    local target_ext
    target_ext="$(select_target_ext)" || pause_and_exit 1

    local current_dir
    current_dir="$PWD"

    if [[ "$mode" == "single" ]]; then
        local file_path
        read -r -p "Ruta del archivo de audio: " file_path

        "$py_cmd" "$PY_TOOL" \
            --kind "audio" \
            --operation "convert" \
            --mode "single" \
            --workdir "$current_dir" \
            --target-ext "$target_ext" \
            --input "$file_path" || pause_and_exit 1

        pause_and_exit 0
    fi

    local filter_ext
    read -r -p "Extensión origen a procesar (ej: mp3, wav, flac): " filter_ext

    "$py_cmd" "$PY_TOOL" \
        --kind "audio" \
        --operation "convert" \
        --mode "all" \
        --workdir "$current_dir" \
        --target-ext "$target_ext" \
        --filter-ext "$filter_ext" || pause_and_exit 1

    pause_and_exit 0
}

main "$@"
