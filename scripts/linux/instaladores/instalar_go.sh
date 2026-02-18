#!/bin/bash

# Script para instalar Go en Linux

set -e

# Versión de Go a instalar (puedes cambiarla)
GO_VERSION="${1:-1.22.0}"
GO_OS="linux"
GO_ARCH="amd64"

# Detectar arquitectura
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        GO_ARCH="amd64"
        ;;
    aarch64|arm64)
        GO_ARCH="arm64"
        ;;
    armv6l)
        GO_ARCH="armv6l"
        ;;
    *)
        echo "❌ Arquitectura no soportada: $ARCH"
        exit 1
        ;;
esac

GO_TARBALL="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"
INSTALL_DIR="/usr/local"

echo "🚀 Instalando Go ${GO_VERSION} para ${GO_OS}-${GO_ARCH}"
echo ""

# Verificar si Go ya está instalado
if command -v go &> /dev/null; then
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo "⚠️  Go ya está instalado (versión: $CURRENT_VERSION)"
    echo "🗑️  Removiendo versión anterior..."
    sudo rm -rf $INSTALL_DIR/go
fi

# Crear directorio temporal
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# Descargar Go
echo "📥 Descargando Go ${GO_VERSION}..."
if ! curl -LO $GO_URL; then
    echo "❌ Error al descargar Go. Verifica la versión: $GO_VERSION"
    echo "Versiones disponibles en: https://go.dev/dl/"
    rm -rf $TMP_DIR
    exit 1
fi

# Extraer e instalar
echo "📦 Instalando Go en $INSTALL_DIR..."
sudo tar -C $INSTALL_DIR -xzf $GO_TARBALL

# Limpiar
cd ~
rm -rf $TMP_DIR

# Configurar variables de entorno
echo ""
echo "⚙️  Configurando variables de entorno..."

SHELL_CONFIG=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Verificar si ya existe la configuración
    if ! grep -q "export PATH=\$PATH:$INSTALL_DIR/go/bin" "$SHELL_CONFIG"; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Go configuration" >> "$SHELL_CONFIG"
        echo "export PATH=\$PATH:$INSTALL_DIR/go/bin" >> "$SHELL_CONFIG"
        echo "export GOPATH=\$HOME/go" >> "$SHELL_CONFIG"
        echo "export PATH=\$PATH:\$GOPATH/bin" >> "$SHELL_CONFIG"
        echo "✅ Variables agregadas a $SHELL_CONFIG"
    else
        echo "ℹ️  Variables de entorno ya configuradas en $SHELL_CONFIG"
    fi
fi

# Crear GOPATH
mkdir -p $HOME/go/{bin,src,pkg}

# Verificar instalación
export PATH=$PATH:$INSTALL_DIR/go/bin
GO_INSTALLED_VERSION=$($INSTALL_DIR/go/bin/go version)

echo ""
echo "✅ ¡Go instalado exitosamente!"
echo "   $GO_INSTALLED_VERSION"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Reinicia tu terminal o ejecuta: source $SHELL_CONFIG"
echo "   2. Verifica la instalación con: go version"
echo "   3. Tu GOPATH está en: $HOME/go"
