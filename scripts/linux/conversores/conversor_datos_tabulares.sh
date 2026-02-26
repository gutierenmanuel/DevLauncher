#!/usr/bin/env bash
# Script: Conversor de datos tabulares (Excel/CSV/JSON/Parquet) por archivo o por lote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_TOOL="$SCRIPT_DIR/../../lib/datos_tabulares.py"

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

select_operation() {
    echo ""
    echo "Selecciona conversión tabular:"
    echo "1) Excel -> CSVs (uno por hoja)"
    echo "2) CSV -> Excel"
    echo "3) JSON -> CSV"
    echo "4) CSV -> JSON"
    echo "5) JSON -> Excel"
    echo "6) Excel -> JSON (uno por hoja)"
    echo "7) Parquet -> CSV"
    echo "8) CSV -> Parquet"
    echo "9) Parquet -> JSON"
    echo "10) JSON -> Parquet"
    echo "11) Parquet -> Excel"
    echo "12) Excel -> Parquet (uno por hoja)"
    echo "13) XML -> CSV"
    echo "14) CSV -> XML"
    echo "15) SQLite -> CSVs (uno por tabla)"
    echo "16) CSV -> SQLite"
    echo "17) SQLite -> Excel"
    echo "18) Excel -> SQLite"
    echo "19) ODS -> CSVs (uno por hoja)"
    echo "20) CSV -> ODS"
    echo "21) ODS -> Excel"
    echo "22) Excel -> ODS"
    echo "23) YAML -> JSON"
    echo "24) JSON -> YAML"
    echo "25) YAML -> CSV"
    echo "26) CSV -> YAML"
    echo "27) CSV -> CSV.GZ"
    echo "28) CSV.GZ -> CSV"
    echo "29) JSON -> JSON.GZ"
    echo "30) JSON.GZ -> JSON"
    echo "31) Parquet -> Feather"
    echo "32) Feather -> Parquet"
    echo "33) JSON -> JSONL"
    echo "34) JSONL -> JSON"
    echo "35) ENV -> JSON"
    echo "36) JSON -> ENV"
    echo "37) INI -> YAML"
    echo "38) YAML -> INI"
    echo "39) CSV -> SQL INSERT"
    echo "40) JSON -> SQL INSERT"
    echo "41) SQL INSERT -> CSV"
    echo "42) SQL INSERT -> JSON"

    local option
    read -r -p "Opción: " option

    case "$option" in
        1) echo "excel_to_csvs" ;;
        2) echo "csv_to_excel" ;;
        3) echo "json_to_csv" ;;
        4) echo "csv_to_json" ;;
        5) echo "json_to_excel" ;;
        6) echo "excel_to_json" ;;
        7) echo "parquet_to_csv" ;;
        8) echo "csv_to_parquet" ;;
        9) echo "parquet_to_json" ;;
        10) echo "json_to_parquet" ;;
        11) echo "parquet_to_excel" ;;
        12) echo "excel_to_parquet" ;;
        13) echo "xml_to_csv" ;;
        14) echo "csv_to_xml" ;;
        15) echo "sqlite_to_csv" ;;
        16) echo "csv_to_sqlite" ;;
        17) echo "sqlite_to_excel" ;;
        18) echo "excel_to_sqlite" ;;
        19) echo "ods_to_csv" ;;
        20) echo "csv_to_ods" ;;
        21) echo "ods_to_excel" ;;
        22) echo "excel_to_ods" ;;
        23) echo "yaml_to_json" ;;
        24) echo "json_to_yaml" ;;
        25) echo "yaml_to_csv" ;;
        26) echo "csv_to_yaml" ;;
        27) echo "csv_to_csv_gz" ;;
        28) echo "csv_gz_to_csv" ;;
        29) echo "json_to_json_gz" ;;
        30) echo "json_gz_to_json" ;;
        31) echo "parquet_to_feather" ;;
        32) echo "feather_to_parquet" ;;
        33) echo "json_to_jsonl" ;;
        34) echo "jsonl_to_json" ;;
        35) echo "env_to_json" ;;
        36) echo "json_to_env" ;;
        37) echo "ini_to_yaml" ;;
        38) echo "yaml_to_ini" ;;
        39) echo "csv_to_sql_insert" ;;
        40) echo "json_to_sql_insert" ;;
        41) echo "sql_insert_to_csv" ;;
        42) echo "sql_insert_to_json" ;;
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
    echo "2) Todos los archivos del tipo de origen"

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
        echo "No se encontró el motor de conversión: $PY_TOOL" >&2
        pause_and_exit 1
    fi

    local py_cmd
    py_cmd="$(resolve_python)" || {
        echo "No se encontró Python (python3/python) en el PATH." >&2
        pause_and_exit 1
    }

    local operation
    operation="$(select_operation)" || pause_and_exit 1

    local mode
    mode="$(select_mode)" || pause_and_exit 1

    local current_dir
    current_dir="$PWD"

    if [[ "$mode" == "single" ]]; then
        local file_path
        read -r -p "Ruta del archivo a convertir: " file_path

        "$py_cmd" "$PY_TOOL" \
            --operation "$operation" \
            --mode "single" \
            --workdir "$current_dir" \
            --input "$file_path" || pause_and_exit 1

        pause_and_exit 0
    fi

    "$py_cmd" "$PY_TOOL" \
        --operation "$operation" \
        --mode "all" \
        --workdir "$current_dir" || pause_and_exit 1

    pause_and_exit 0
}

main "$@"
