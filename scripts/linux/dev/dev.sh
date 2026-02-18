#!/bin/bash

# Script de desarrollo para Wails con Hot-Reload
# Autor: DevLauncher Project

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

# Configurar manejo de errores
set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Wails Development Mode 🔥" "Hot-Reload activado"

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar dependencias con manejo de errores mejorado
info "Verificando dependencias..."
echo ""

check_command "go" "GO_NOT_FOUND" "Go no está instalado" || exit 1
show_version "go" "version"

check_command "wails" "WAILS_NOT_FOUND" "Wails CLI no está instalado" || exit 1
success "Wails CLI instalado"

check_command "pnpm" "PNPM_NOT_FOUND" "pnpm no está instalado" || exit 1
show_version "pnpm" "--version"

echo ""

success "Usando frontend directamente desde ./frontend/"
info "No es necesario copiar archivos"
echo ""

# Verificar dependencias del frontend
progress "Verificando dependencias del frontend..."

if [ ! -d "frontend" ]; then
    handle_error "DIRECTORY_NOT_FOUND" "No se encuentra el directorio 'frontend'" \
        "Verifica que estés en el directorio correcto del proyecto"
    exit 1
fi

cd frontend || exit 1

if [ ! -d "node_modules" ]; then
    progress "Instalando dependencias con pnpm..."
    if ! pnpm install; then
        cd - > /dev/null
        handle_error "NPM_INSTALL_FAILED" "Falló la instalación de dependencias" \
            "Verifica tu conexión a internet y que package.json sea válido"
        exit 1
    fi
else
    success "Dependencias ya instaladas"
fi

cd - > /dev/null
echo ""

# Verificar directorio de Wails
if [ ! -d "wails-app" ]; then
    handle_error "DIRECTORY_NOT_FOUND" "No se encuentra el directorio 'wails-app'" \
        "Verifica que estés en el directorio correcto del proyecto"
    exit 1
fi

cd wails-app || exit 1

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Iniciando Wails Dev Server...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
success "🔥 Hot-Reload activado"
info "   Frontend: Vite + React + Tailwind"
info "   Backend:  Go + WSL Manager"
info "   Modo:     Directo (sin copia)"
echo ""
warning "Presiona Ctrl+C para detener"
echo ""

# Ejecutar Wails en modo desarrollo
if ! wails dev; then
    handle_error "WAILS_DEV_FAILED" "El servidor de desarrollo falló" \
        "Revisa los logs anteriores para más detalles del error"
    exit 1
fi
