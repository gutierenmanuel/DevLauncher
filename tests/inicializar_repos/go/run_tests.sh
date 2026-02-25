#!/bin/bash

# Test runner para scripts de inicialización de repos Go
# Ejecuta los scripts en subcarpetas separadas para evaluación manual
#
# Uso:
#   ./run_tests.sh           # Ejecuta todos los tests
#   ./run_tests.sh module    # Solo init_go_module.sh
#   ./run_tests.sh project   # Solo init_go_proyect.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts/linux/inicializar_repos/go"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Tests: Inicialización de Repos Go 🐹                     ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

FILTER="${1:-all}"

run_test() {
    local name="$1"
    local script="$2"
    local env_vars="$3"
    local test_dir="$OUTPUT_DIR/$name"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Test: $name${NC}"
    echo -e "${BLUE}  Script: $script${NC}"
    echo -e "${BLUE}  Output: $test_dir${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Limpiar y crear directorio de salida
    rm -rf "$test_dir"
    mkdir -p "$test_dir"

    # Ejecutar script en el directorio de test
    local log_file="$test_dir/_test.log"
    local start_time
    start_time=$(date +%s)

    if (cd "$test_dir" && eval "$env_vars" bash "$script") > "$log_file" 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${GREEN}✓ PASS${NC} — $name (${duration}s)"
        echo "EXIT_CODE=0" >> "$log_file"
    else
        local exit_code=$?
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}✗ FAIL${NC} — $name (exit code: $exit_code, ${duration}s)"
        echo "EXIT_CODE=$exit_code" >> "$log_file"
    fi

    # Mostrar estructura generada
    echo -e "${YELLOW}  Estructura generada:${NC}"
    if command -v tree &>/dev/null; then
        tree "$test_dir" -L 3 --dirsfirst -I '_test.log' 2>/dev/null | head -30 | sed 's/^/    /'
    else
        find "$test_dir" -maxdepth 3 -not -name '_test.log' | sort | head -30 | sed 's/^/    /'
    fi
    echo ""
}

# ==========================================
# TEST: init_go_module.sh
# ==========================================
if [ "$FILTER" = "all" ] || [ "$FILTER" = "module" ]; then
    run_test "go_module" \
        "$SCRIPTS_DIR/init_go_module.sh" \
        ""
fi

# ==========================================
# TEST: init_go_proyect.sh
# ==========================================
if [ "$FILTER" = "all" ] || [ "$FILTER" = "project" ]; then
    run_test "go_project" \
        "$SCRIPTS_DIR/init_go_proyect.sh" \
        "DL_PROJECT_NAME=test-go-project DL_GO_MODULE=github.com/test/test-go-project DL_FORCE_OVERWRITE=1"
fi

# ==========================================
# RESUMEN
# ==========================================
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tests completados${NC}"
echo -e "Resultados en: ${BLUE}$OUTPUT_DIR/${NC}"
echo -e "${YELLOW}Revisa manualmente la estructura y logs de cada test${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
