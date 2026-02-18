#!/bin/bash

# Script para instalar Volta en Linux
# Volta es un gestor de versiones de Node.js rápido y confiable

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Instalador de Volta ⚡" "Gestor de versiones de Node.js"

# Verificar si Volta ya está instalado
if command -v volta &> /dev/null; then
    warning "Volta ya está instalado"
    show_version "volta" "--version"
    echo ""
    
    if ! confirm "¿Deseas reinstalar Volta?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    echo ""
fi

# Verificar dependencias (curl)
progress "Verificando dependencias..."
check_command "curl" "CURL_NOT_FOUND" "curl no está instalado (requerido para descargar Volta)" || {
    info "Puedes instalarlo con: sudo apt install curl"
    exit 1
}
echo ""

# Descargar e instalar Volta
progress "⬇️  Descargando e instalando Volta..."
info "Ejecutando el instalador oficial de Volta..."
echo ""

if ! curl https://get.volta.sh | bash; then
    handle_error "INSTALL_FAILED" "Falló la instalación de Volta" \
        "Verifica tu conexión a internet y que curl funcione correctamente"
    exit 1
fi

echo ""

# Configurar variables de entorno
progress "⚙️  Configurando variables de entorno..."

VOLTA_HOME="$HOME/.volta"
export VOLTA_HOME
export PATH="$VOLTA_HOME/bin:$PATH"

# Agregar a .bashrc si no está
if ! grep -q "VOLTA_HOME" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Volta configuration" >> "$HOME/.bashrc"
    echo 'export VOLTA_HOME="$HOME/.volta"' >> "$HOME/.bashrc"
    echo 'export PATH="$VOLTA_HOME/bin:$PATH"' >> "$HOME/.bashrc"
    success "Variables agregadas a ~/.bashrc"
else
    info "Variables ya configuradas en ~/.bashrc"
fi

# Si usa zsh, agregarlo también
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "VOLTA_HOME" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Volta configuration" >> "$HOME/.zshrc"
        echo 'export VOLTA_HOME="$HOME/.volta"' >> "$HOME/.zshrc"
        echo 'export PATH="$VOLTA_HOME/bin:$PATH"' >> "$HOME/.zshrc"
        success "Variables agregadas a ~/.zshrc"
    fi
fi

echo ""

# Verificar instalación
if ! command -v volta &> /dev/null; then
    # Intentar cargar desde la ubicación predeterminada
    if [ -f "$HOME/.volta/bin/volta" ]; then
        warning "Volta instalado pero no está en el PATH actual"
        info "Ejecuta: source ~/.bashrc"
        echo ""
        info "O abre una nueva terminal"
    else
        handle_error "INSTALL_FAILED" "Volta no se encuentra disponible después de la instalación" \
            "Puede que necesites cerrar y abrir la terminal nuevamente"
        exit 1
    fi
else
    success "✅ Volta instalado correctamente!"
    show_version "volta" "--version"
fi

echo ""
info "🎉 ¡Instalación completada!"
echo ""
info "Próximos pasos:"
echo -e "  ${CYAN}1.${NC} Recarga tu shell: ${GREEN}source ~/.bashrc${NC}"
echo -e "  ${CYAN}2.${NC} Instala Node.js: ${GREEN}volta install node${NC}"
echo -e "  ${CYAN}3.${NC} Instala pnpm: ${GREEN}volta install pnpm${NC}"
echo ""
info "Comandos útiles de Volta:"
echo -e "  ${GREEN}volta install node@20${NC}     - Instalar Node.js versión 20"
echo -e "  ${GREEN}volta install node@latest${NC} - Instalar última versión de Node"
echo -e "  ${GREEN}volta install npm${NC}         - Instalar npm"
echo -e "  ${GREEN}volta install yarn${NC}        - Instalar yarn"
echo -e "  ${GREEN}volta list${NC}                - Ver herramientas instaladas"
echo ""
success "🚀 Volta está listo para gestionar tus versiones de Node!"
