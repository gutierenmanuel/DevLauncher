#!/bin/bash
# uninstall.sh — Elimina la configuración instalada por install.sh
# Remueve el bloque "# Scripts Development Launcher" del rc del shell.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Desinstalador de Scripts de Desarrollo                  ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detectar rc file
SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

echo -e "${CYAN}→ Archivo de configuración: $SHELL_RC${NC}"
echo ""

# Verificar si existe el bloque
if ! grep -q "# Scripts Development Launcher" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}⚠ No se encontró ninguna instalación previa en $SHELL_RC${NC}"
    echo ""
    exit 0
fi

echo -e "${YELLOW}⚠ Se encontró la siguiente configuración instalada:${NC}"
echo ""
grep -A 60 "# Scripts Development Launcher" "$SHELL_RC" | grep -B 60 "# End Scripts Development Launcher"
echo ""

echo -ne "${CYAN}¿Deseas eliminarla? (s/n): ${NC}"
read -r response
if [[ ! "$response" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}Desinstalación cancelada.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}→ Eliminando configuración...${NC}"
sed -i '/# Scripts Development Launcher/,/# End Scripts Development Launcher/d' "$SHELL_RC"

# Limpiar líneas en blanco extra al final
sed -i -e '/^[[:space:]]*$/{ /^\n*$/d; }' "$SHELL_RC" 2>/dev/null || true

echo -e "${GREEN}✓ Configuración eliminada de $SHELL_RC${NC}"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Desinstalación completada${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Para aplicar los cambios, ejecuta:${NC}"
echo -e "   ${YELLOW}source $SHELL_RC${NC}"
echo ""
echo -e "${CYAN}Si también quieres eliminar los scripts del sistema,${NC}"
echo -e "${CYAN}usa el ejecutable: ${YELLOW}./installer-linux${NC} y elige Desinstalar."
echo ""
