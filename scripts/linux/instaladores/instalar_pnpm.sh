#!/bin/bash

# Script para instalar pnpm en Linux

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Instalador de pnpm 📦" "Gestor de paquetes rápido para Node.js"

# Verificar si pnpm ya está instalado
if command -v pnpm &> /dev/null; then
    warning "pnpm ya está instalado"
    show_version "pnpm" "--version"
    echo ""
    
    if ! confirm "¿Deseas reinstalar/actualizar pnpm?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    echo ""
fi

# Verificar que npm esté instalado
progress "Verificando dependencias..."
check_command "npm" "NPM_NOT_FOUND" "npm no está instalado (requerido para instalar pnpm)" || exit 1
show_version "npm" "--version"
echo ""

# Instalar pnpm globalmente
progress "📦 Instalando pnpm globalmente..."
if ! npm install -g pnpm; then
    handle_error "INSTALL_FAILED" "Falló la instalación de pnpm" \
        "Intenta ejecutar el comando con sudo: sudo npm install -g pnpm"
    exit 1
fi

echo ""

# Verificar instalación
if ! command -v pnpm &> /dev/null; then
    handle_error "INSTALL_FAILED" "pnpm no se encuentra disponible después de la instalación" \
        "Verifica que npm/bin esté en tu PATH"
    exit 1
fi

success "✅ pnpm instalado correctamente!"
show_version "pnpm" "--version"

echo ""
info "🎉 ¡Instalación completada!"
echo ""
info "Comandos útiles:"
echo -e "  ${GREEN}pnpm install${NC}    - Instalar dependencias"
echo -e "  ${GREEN}pnpm add <pkg>${NC}  - Agregar paquete"
echo -e "  ${GREEN}pnpm run <cmd>${NC}  - Ejecutar script"
echo ""
