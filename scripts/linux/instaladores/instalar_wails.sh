#!/bin/bash

# Script para instalar Wails en Linux

set -e

echo "🚀 Instalando Wails"
echo ""

# Verificar si Go está instalado
if ! command -v go &> /dev/null; then
    echo "❌ Go no está instalado"
    echo "   Instálalo primero con: ./scripts/instaladores/instalar_go.sh"
    exit 1
fi

GO_VERSION=$(go version)
echo "✅ Go detectado: $GO_VERSION"
echo ""

# Detectar distribución de Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ No se pudo detectar la distribución de Linux"
    exit 1
fi

echo "📦 Instalando dependencias del sistema para $DISTRO..."
echo ""

# Instalar dependencias según la distribución
case $DISTRO in
    ubuntu|debian|linuxmint|pop)
        sudo apt update
        sudo apt install -y libgtk-3-dev libwebkit2gtk-4.0-dev build-essential pkg-config
        ;;
    fedora|rhel|centos)
        sudo dnf install -y gtk3-devel webkit2gtk3-devel gcc-c++ pkgconfig
        ;;
    arch|manjaro)
        sudo pacman -Sy --noconfirm gtk3 webkit2gtk base-devel
        ;;
    opensuse*)
        sudo zypper install -y gtk3-devel webkit2gtk3-devel gcc-c++ pkg-config
        ;;
    *)
        echo "⚠️  Distribución no reconocida: $DISTRO"
        echo "   Instala manualmente: gtk3, webkit2gtk, build-essential, pkg-config"
        echo "   Continuando con la instalación de Wails..."
        ;;
esac

echo ""
echo "📦 Instalando Wails CLI..."
go install github.com/wailsapp/wails/v2/cmd/wails@latest

# Verificar que GOPATH/bin esté en PATH
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo ""
    echo "⚠️  $HOME/go/bin no está en tu PATH"
    echo "   Añadiendo a ~/.bashrc o ~/.zshrc..."
    
    SHELL_CONFIG=""
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" "$SHELL_CONFIG"; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Go binaries" >> "$SHELL_CONFIG"
            echo "export PATH=\$PATH:\$HOME/go/bin" >> "$SHELL_CONFIG"
        fi
    fi
    
    export PATH=$PATH:$HOME/go/bin
fi

# Verificar instalación
if command -v wails &> /dev/null; then
    WAILS_VERSION=$(wails version)
    echo ""
    echo "✅ ¡Wails instalado exitosamente!"
    echo "$WAILS_VERSION"
    echo ""
    echo "📝 Comandos básicos de Wails:"
    echo "   - wails init -n myapp -t vanilla  # Crear nuevo proyecto"
    echo "   - wails dev                        # Modo desarrollo"
    echo "   - wails build                      # Build producción"
    echo "   - wails doctor                     # Verificar instalación"
    echo ""
    echo "📚 Templates disponibles:"
    echo "   - vanilla, vue, react, svelte, lit, angular"
    echo ""
    echo "📖 Más info: https://wails.io/"
    echo ""
    echo "⚠️  Si acabas de instalar, reinicia tu terminal o ejecuta:"
    echo "   source ~/.bashrc   # o ~/.zshrc según tu shell"
else
    echo ""
    echo "⚠️  Wails instalado pero no está en PATH"
    echo "   Reinicia tu terminal o ejecuta: source ~/.bashrc"
fi
