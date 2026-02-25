#!/bin/bash

# Test runner para scripts de inicialización de proyectos Frontend
# Ejecuta los scripts en subcarpetas separadas para evaluación manual
#
# Uso:
#   ./run_tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts/linux/inicializar_repos/frontend"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Tests: Inicialización de Repos Frontend 🌐               ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

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

    rm -rf "$test_dir"
    mkdir -p "$test_dir"

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

    echo -e "${YELLOW}  Estructura generada:${NC}"
    if command -v tree &>/dev/null; then
        tree "$test_dir" -L 3 --dirsfirst -I '_test.log|node_modules|.git' 2>/dev/null | head -40 | sed 's/^/    /'
    else
        find "$test_dir" -maxdepth 3 -not -name '_test.log' -not -path '*/node_modules/*' -not -path '*/.git/*' | sort | head -40 | sed 's/^/    /'
    fi
    echo ""
}

# ==========================================
# TEST: init_frontend_project.sh
# ==========================================
run_test "frontend_project" \
    "$SCRIPTS_DIR/init_frontend_project.sh" \
    ""

# ==========================================
# RESUMEN
# ==========================================
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tests completados${NC}"
echo -e "Resultados en: ${BLUE}$OUTPUT_DIR/${NC}"
echo -e "${YELLOW}Revisa manualmente la estructura y logs de cada test${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
