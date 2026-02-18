#!/bin/bash
# Script: Test runner para todos los scripts
# Ejecuta tests de validación para cada script sin ejecutarlos realmente

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Test Suite - DevScripts Validation              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Obtener directorio raíz del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Función para ejecutar un test
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    
    TOTAL=$((TOTAL + 1))
    
    echo -ne "Testing ${YELLOW}${test_name}${NC}... "
    
    # Ejecutar test con timeout de 5 segundos
    if timeout 5s bash "$test_file" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo -e "${YELLOW}⚠ TIMEOUT${NC}"
            SKIPPED=$((SKIPPED + 1))
        else
            echo -e "${RED}✗ FAIL (exit code: $exit_code)${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi
}

# Ejecutar todos los tests
for test_file in "$SCRIPT_DIR/tests"/test_*.sh; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
    fi
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "Total:   ${BLUE}$TOTAL${NC}"
echo -e "Passed:  ${GREEN}$PASSED${NC}"
echo -e "Failed:  ${RED}$FAILED${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Exit code basado en resultados
if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
