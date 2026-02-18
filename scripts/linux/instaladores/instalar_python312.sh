#!/bin/bash

# Script para instalar Python 3.12 en Linux
# Instalación mediante deadsnakes PPA para Ubuntu/Debian

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Instalador de Python 3.12 🐍" "Última versión estable de Python"

# Detectar distribución
progress "Detectando distribución de Linux..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
    info "Distribución detectada: $DISTRO $VERSION"
else
    warning "No se pudo detectar la distribución automáticamente"
    DISTRO="unknown"
fi

echo ""

# Verificar si Python 3.12 ya está instalado
if command -v python3.12 &> /dev/null; then
    success "Python 3.12 ya está instalado"
    show_version "python3.12" "--version"
    echo ""
    
    if ! confirm "¿Deseas continuar con la instalación/actualización?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    echo ""
fi

# Instalar según distribución
case "$DISTRO" in
    ubuntu|debian|pop|mint|elementary)
        info "Instalando Python 3.12 usando deadsnakes PPA..."
        echo ""
        
        # Verificar permisos de sudo
        if ! sudo -n true 2>/dev/null; then
            warning "Se requieren permisos de administrador"
            info "Se te pedirá tu contraseña"
            echo ""
        fi
        
        # Actualizar repositorios e instalar dependencias
        progress "📦 Actualizando repositorios..."
        if ! sudo apt update; then
            handle_error "APT_UPDATE_FAILED" "Falló la actualización de repositorios" \
                "Verifica tu conexión a internet y configuración de apt"
            exit 1
        fi
        
        # Instalar software-properties-common si no está
        progress "Verificando software-properties-common..."
        if ! dpkg -l | grep -q software-properties-common; then
            if ! sudo apt install -y software-properties-common; then
                handle_error "INSTALL_FAILED" "Falló la instalación de software-properties-common" \
                    "Este paquete es necesario para agregar PPAs"
                exit 1
            fi
        fi
        success "Dependencias instaladas"
        echo ""
        
        # Agregar deadsnakes PPA
        progress "➕ Agregando repositorio deadsnakes PPA..."
        if ! sudo add-apt-repository -y ppa:deadsnakes/ppa; then
            handle_error "PPA_ADD_FAILED" "Falló agregar el PPA de deadsnakes" \
                "Verifica tu conexión a internet"
            exit 1
        fi
        success "PPA agregado"
        echo ""
        
        # Actualizar lista de paquetes
        progress "📦 Actualizando lista de paquetes..."
        if ! sudo apt update; then
            handle_error "APT_UPDATE_FAILED" "Falló la actualización después de agregar PPA"
            exit 1
        fi
        echo ""
        
        # Instalar Python 3.12 y herramientas esenciales
        progress "⬇️  Instalando Python 3.12 y herramientas..."
        info "Paquetes a instalar: python3.12, python3.12-venv, python3.12-dev, python3-pip"
        echo ""
        
        if ! sudo apt install -y python3.12 python3.12-venv python3.12-dev python3-pip; then
            handle_error "INSTALL_FAILED" "Falló la instalación de Python 3.12" \
                "Revisa los errores de apt arriba"
            exit 1
        fi
        
        success "Python 3.12 instalado correctamente"
        ;;
        
    fedora|rhel|centos)
        info "Instalando Python 3.12 usando dnf..."
        echo ""
        
        progress "⬇️  Instalando Python 3.12..."
        if ! sudo dnf install -y python3.12 python3.12-devel; then
            handle_error "INSTALL_FAILED" "Falló la instalación de Python 3.12" \
                "Puede que necesites habilitar repositorios adicionales"
            exit 1
        fi
        ;;
        
    arch|manjaro)
        info "Instalando Python 3.12 usando pacman..."
        echo ""
        
        progress "⬇️  Instalando Python 3.12..."
        if ! sudo pacman -S --noconfirm python; then
            handle_error "INSTALL_FAILED" "Falló la instalación de Python" \
                "Verifica tu conexión y la configuración de pacman"
            exit 1
        fi
        ;;
        
    *)
        warning "Distribución no soportada automáticamente: $DISTRO"
        echo ""
        info "Opciones manuales:"
        echo -e "  ${CYAN}1.${NC} Compilar desde fuente: https://www.python.org/downloads/"
        echo -e "  ${CYAN}2.${NC} Usar pyenv: curl https://pyenv.run | bash"
        echo ""
        exit 1
        ;;
esac

echo ""

# Verificar instalación
if ! command -v python3.12 &> /dev/null; then
    handle_error "INSTALL_FAILED" "Python 3.12 no se encuentra disponible después de la instalación" \
        "Puede que necesites reiniciar la terminal"
    exit 1
fi

success "✅ Python 3.12 instalado correctamente!"
show_version "python3.12" "--version"

echo ""

# Verificar pip
progress "Verificando pip para Python 3.12..."
if ! python3.12 -m pip --version &> /dev/null; then
    warning "pip no está disponible para Python 3.12"
    info "Instalando pip..."
    
    if ! python3.12 -m ensurepip --upgrade; then
        warning "No se pudo instalar pip con ensurepip"
        info "Puedes instalarlo manualmente con:"
        echo -e "  ${GREEN}curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12${NC}"
    else
        success "pip instalado para Python 3.12"
    fi
else
    success "pip disponible para Python 3.12"
    python3.12 -m pip --version
fi

echo ""
info "🎉 ¡Instalación completada!"
echo ""
info "Comandos útiles:"
echo -e "  ${GREEN}python3.12 --version${NC}      - Ver versión instalada"
echo -e "  ${GREEN}python3.12 -m venv venv${NC}   - Crear entorno virtual"
echo -e "  ${GREEN}python3.12 -m pip install${NC} - Instalar paquetes"
echo ""
info "Crear un proyecto con Python 3.12:"
echo -e "  ${CYAN}# Crear entorno virtual${NC}"
echo -e "  ${GREEN}python3.12 -m venv .venv${NC}"
echo ""
echo -e "  ${CYAN}# Activar entorno${NC}"
echo -e "  ${GREEN}source .venv/bin/activate${NC}"
echo ""
echo -e "  ${CYAN}# Instalar paquetes${NC}"
echo -e "  ${GREEN}pip install requests pandas${NC}"
echo ""
success "🚀 Python 3.12 está listo para usar!"
echo ""
info "💡 Tip: Considera usar ${CYAN}uv${NC} para gestión de paquetes más rápida:"
echo -e "   Instálalo con: ${GREEN}./instalar_uv.sh${NC}"
