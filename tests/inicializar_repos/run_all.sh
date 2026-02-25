#!/bin/bash

# Runner global de tests para todos los scripts de inicialización de repos
# Ejecuta cada categoría en su carpeta de output separada
#
# Uso:
#   ./run_all.sh             # Ejecuta todo
#   ./run_all.sh go          # Solo tests de Go
#   ./run_all.sh python      # Solo tests de Python
#   ./run_all.sh frontend    # Solo tests de Frontend
#   ./run_all.sh wails       # Solo tests de Wails
#   ./run_all.sh data        # Solo tests de Data

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-all}"
TOTAL_PASS=0
TOTAL_FAIL=0

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   🧪 Tests: Inicialización de Repos (todas las categorías) ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

run_category() {
    local category="$1"
    local runner="$SCRIPT_DIR/$category/run_tests.sh"

    if [ ! -f "$runner" ]; then
        echo -e "${YELLOW}⚠ No hay runner para: $category${NC}"
        return
    fi

    echo ""
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Categoría: $category${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""

    if bash "$runner"; then
        TOTAL_PASS=$((TOTAL_PASS + 1))
    else
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
}

CATEGORIES=("go" "python" "frontend" "wails" "data")

for cat in "${CATEGORIES[@]}"; do
    if [ "$FILTER" = "all" ] || [ "$FILTER" = "$cat" ]; then
        run_category "$cat"
    fi
done

# ==========================================
# RESUMEN GLOBAL
# ==========================================
echo ""
echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Resumen Global                                          ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}✓ Categorías OK:${NC}   $TOTAL_PASS"
echo -e "  ${RED}✗ Categorías FAIL:${NC} $TOTAL_FAIL"
echo ""
echo -e "Resultados por carpeta:"

for cat in "${CATEGORIES[@]}"; do
    if [ "$FILTER" = "all" ] || [ "$FILTER" = "$cat" ]; then
        local_output="$SCRIPT_DIR/$cat/output"
        if [ -d "$local_output" ]; then
            echo -e "  ${BLUE}$local_output/${NC}"
        fi
    fi
done

echo ""
echo -e "${YELLOW}Revisa cada carpeta output/ para evaluar los resultados manualmente${NC}"
