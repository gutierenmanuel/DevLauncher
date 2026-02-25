#!/bin/bash

# Script: Refresca la terminal recargando el PATH y variables de entorno
# Reemplaza la shell actual con una nueva instancia, recargando .bashrc/.zshrc

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

show_header "Refrescar Terminal 🔄" "Recarga PATH y variables de entorno"

# Detectar shell actual
CURRENT_SHELL="${SHELL:-/bin/bash}"
SHELL_NAME="$(basename "$CURRENT_SHELL")"

info "Shell detectada: ${BOLD}$SHELL_NAME${NC}"
echo ""

# Mostrar PATH actual (resumido)
progress "PATH actual (primeros 5 directorios):"
echo "$PATH" | tr ':' '\n' | head -5 | while read -r p; do
    echo -e "  ${GREEN}→${NC} $p"
done
TOTAL_PATHS=$(echo "$PATH" | tr ':' '\n' | wc -l)
if [ "$TOTAL_PATHS" -gt 5 ]; then
    echo -e "  ${GRAY}... y $((TOTAL_PATHS - 5)) más${NC}"
fi
echo ""

# Determinar archivo RC
case "$SHELL_NAME" in
    bash) RC_FILE="$HOME/.bashrc" ;;
    zsh)  RC_FILE="$HOME/.zshrc" ;;
    fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
    *)    RC_FILE="" ;;
esac

if [ -n "$RC_FILE" ] && [ -f "$RC_FILE" ]; then
    info "Archivo de configuración: ${BOLD}$RC_FILE${NC}"
else
    warning "No se encontró archivo RC para $SHELL_NAME"
fi
echo ""

# Refrescar: reemplazar shell con nueva instancia
success "La terminal se refrescará al salir del launcher"
info "Se ejecutará: ${BOLD}exec $CURRENT_SHELL -l${NC}"
echo ""

# Escribir marcador para que el launcher (o el usuario) sepa que debe refrescar
# El truco: exec reemplaza el proceso actual con una nueva shell
exec "$CURRENT_SHELL" -l
