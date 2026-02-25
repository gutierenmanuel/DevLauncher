#!/bin/bash

# Limpia todos los outputs generados por los tests de inicialización de repos
#
# Uso:
#   ./clean.sh           # Limpia todo
#   ./clean.sh go        # Solo limpia go/output
#   ./clean.sh data      # Solo limpia data/output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-all}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

CATEGORIES=("go" "python" "frontend" "wails" "data")
CLEANED=0

for cat in "${CATEGORIES[@]}"; do
    if [ "$FILTER" = "all" ] || [ "$FILTER" = "$cat" ]; then
        output_dir="$SCRIPT_DIR/$cat/output"
        if [ -d "$output_dir" ]; then
            rm -rf "$output_dir"
            echo -e "${GREEN}✓${NC} $cat/output/ eliminado"
            CLEANED=$((CLEANED + 1))
        else
            echo -e "${YELLOW}–${NC} $cat/output/ no existe"
        fi
    fi
done

echo ""
echo -e "${PURPLE}$CLEANED carpeta(s) limpiada(s)${NC}"
