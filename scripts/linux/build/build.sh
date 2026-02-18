#!/bin/bash

# Script de compilación para DevLauncher
# Sistema de build completo para aplicaciones Wails

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "DevLauncher Build System 🏗️" "Compilando aplicación Wails"

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar dependencias
info "Verificando herramientas necesarias..."
echo ""

check_command "go" "GO_NOT_FOUND" || exit 1
show_version "go" "version"

check_command "wails" "WAILS_NOT_FOUND" || exit 1
success "Wails CLI instalado"

check_command "pnpm" "PNPM_NOT_FOUND" || exit 1
show_version "pnpm" "--version"

echo ""

OUTPUT_DIR="./bin"
mkdir -p "$OUTPUT_DIR"

echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  Construyendo Aplicación Wails${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar directorios
progress "Verificando estructura del proyecto..."

if [ ! -d "frontend" ]; then
    handle_error "DIRECTORY_NOT_FOUND" "No se encuentra el directorio 'frontend'" \
        "Verifica que estés en el directorio correcto del proyecto"
    exit 1
fi

if [ ! -d "wails-app" ]; then
    handle_error "DIRECTORY_NOT_FOUND" "No se encuentra el directorio 'wails-app'" \
        "Verifica que estés en el directorio correcto del proyecto"
    exit 1
fi

success "Estructura del proyecto correcta"
echo ""

# Limpiar build anterior
progress "🧹 Limpiando builds anteriores..."
rm -rf wails-app/build wails-app/frontend frontend/dist
success "Limpieza completada"
echo ""

# Instalar y compilar frontend
progress "📦 Instalando dependencias del frontend..."
cd frontend || exit 1

if ! pnpm install; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de dependencias" \
        "Verifica tu conexión a internet y que package.json sea válido"
    exit 1
fi

echo ""
progress "🎨 Compilando frontend..."
if ! pnpm build; then
    cd ..
    handle_error "BUILD_FAILED" "Falló la compilación del frontend" \
        "Revisa los errores de compilación arriba"
    exit 1
fi

if [ ! -f "dist/index.html" ]; then
    cd ..
    handle_error "BUILD_FAILED" "El frontend no se compiló correctamente" \
        "No se encontró dist/index.html después del build"
    exit 1
fi

success "Frontend compilado correctamente"
cd ..
echo ""

# Copiar frontend a wails-app
progress "🔗 Copiando frontend a wails-app..."
mkdir -p wails-app/frontend
cp -r frontend/dist wails-app/frontend/

if [ ! -f "wails-app/frontend/dist/index.html" ]; then
    handle_error "BUILD_FAILED" "No se copió correctamente el frontend" \
        "Verifica los permisos de escritura"
    exit 1
fi

success "Frontend copiado a wails-app/frontend/dist"
echo ""

# Compilar Wails
cd wails-app || exit 1

echo ""
progress "🪟 Construyendo para Windows (DEBUG con consola)..."
if ! wails build -platform windows/amd64 -debug -o devlauncher-debug.exe; then
    cd ..
    handle_error "BUILD_FAILED" "Falló el build de Wails en modo debug" \
        "Revisa los errores de compilación de Go arriba"
    exit 1
fi

if [ -f "build/bin/devlauncher-debug.exe" ]; then
    cp build/bin/devlauncher-debug.exe "../$OUTPUT_DIR/devlauncher-windows-debug.exe"
    success "✅ Debug build completo!"
else
    cd ..
    handle_error "BUILD_FAILED" "El ejecutable debug no se generó" \
        "Verifica que Wails se haya instalado correctamente"
    exit 1
fi

echo ""
progress "🪟 Construyendo para Windows (PRODUCCIÓN sin consola)..."
if ! wails build -platform windows/amd64 -ldflags "-H windowsgui" -o devlauncher.exe; then
    cd ..
    handle_error "BUILD_FAILED" "Falló el build de Wails en modo producción" \
        "Revisa los errores de compilación de Go arriba"
    exit 1
fi

if [ -f "build/bin/devlauncher.exe" ]; then
    cp build/bin/devlauncher.exe "../$OUTPUT_DIR/devlauncher-windows.exe"
    success "✅ Production build completo!"
else
    cd ..
    handle_error "BUILD_FAILED" "El ejecutable de producción no se generó" \
        "Verifica que Wails se haya instalado correctamente"
    exit 1
fi

cd ..

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
success "✨ Build completado exitosamente!"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
info "Archivos generados:"
ls -lh "$OUTPUT_DIR"
echo ""
info "🚀 Para copiar a Windows:"
echo -e "   ${GREEN}bash scripts/linux/dev/copy-to-windows.sh${NC}"
echo ""
