#!/bin/bash

# Script para instalar uv en Linux
# uv es una herramienta moderna ultra-rápida para gestión de paquetes Python

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Instalador de uv 🐍⚡" "Gestor de paquetes Python ultra-rápido"

# Verificar si uv ya está instalado
if command -v uv &> /dev/null; then
    warning "uv ya está instalado"
    show_version "uv" "--version"
    echo ""
    
    if ! confirm "¿Deseas actualizar uv a la última versión?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    echo ""
fi

# Verificar dependencias (curl)
progress "Verificando dependencias..."
check_command "curl" "CURL_NOT_FOUND" "curl no está instalado (requerido para descargar uv)" || {
    info "Puedes instalarlo con: sudo apt install curl"
    exit 1
}
echo ""

# Descargar e instalar uv
progress "⬇️  Descargando e instalando uv..."
info "Ejecutando el instalador oficial de uv..."
echo ""

if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
    handle_error "INSTALL_FAILED" "Falló la instalación de uv" \
        "Verifica tu conexión a internet y los permisos"
    exit 1
fi

echo ""

# Configurar PATH
progress "⚙️  Configurando PATH..."

UV_HOME="$HOME/.cargo/bin"

# Agregar a .bashrc si no está
if ! grep -q ".cargo/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# uv and cargo binaries" >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
    success "PATH agregado a ~/.bashrc"
else
    info "PATH ya configurado en ~/.bashrc"
fi

# Si usa zsh, agregarlo también
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q ".cargo/bin" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# uv and cargo binaries" >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
        success "PATH agregado a ~/.zshrc"
    fi
fi

# Cargar el PATH en la sesión actual
export PATH="$HOME/.cargo/bin:$PATH"

echo ""

# Verificar instalación
if ! command -v uv &> /dev/null; then
    warning "uv instalado pero no está en el PATH actual"
    info "Ejecuta: source ~/.bashrc"
    echo ""
    info "O abre una nueva terminal para usar uv"
else
    success "✅ uv instalado correctamente!"
    show_version "uv" "--version"
fi

echo ""
info "🎉 ¡Instalación completada!"
echo ""
info "¿Qué es uv?"
echo -e "  ${GRAY}uv es un gestor de paquetes Python escrito en Rust${NC}"
echo -e "  ${GRAY}Es 10-100x más rápido que pip${NC}"
echo -e "  ${GRAY}Compatible con pip pero mucho más eficiente${NC}"
echo ""
info "Comandos útiles de uv:"
echo -e "  ${GREEN}uv pip install <package>${NC}  - Instalar paquete (como pip)"
echo -e "  ${GREEN}uv venv${NC}                    - Crear entorno virtual"
echo -e "  ${GREEN}uv pip sync requirements.txt${NC} - Sincronizar dependencias"
echo -e "  ${GREEN}uv pip compile pyproject.toml${NC} - Generar requirements.txt"
echo ""
info "Ejemplos:"
echo -e "  ${CYAN}# Crear y activar entorno virtual${NC}"
echo -e "  ${GREEN}uv venv${NC}"
echo -e "  ${GREEN}source .venv/bin/activate${NC}"
echo ""
echo -e "  ${CYAN}# Instalar paquetes rápidamente${NC}"
echo -e "  ${GREEN}uv pip install fastapi uvicorn pandas${NC}"
echo ""
success "🚀 uv está listo para acelerar tu desarrollo Python!"
