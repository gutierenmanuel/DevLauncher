#!/bin/bash

# Script para instalar Node.js en Linux usando nvm (Node Version Manager)

set -e

# Versión de Node.js a instalar
NODE_VERSION="${1:-20}"

echo "🚀 Instalando Node.js v${NODE_VERSION} mediante nvm"
echo ""

# Verificar si Node.js ya está instalado
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version)
    echo "ℹ️  Node.js ya está instalado: $CURRENT_VERSION"
    echo "   Continuando con la instalación/actualización..."
fi

# Verificar si nvm ya está instalado
if [ -d "$HOME/.nvm" ]; then
    echo "✅ nvm ya está instalado"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    # Instalar nvm
    echo "📥 Descargando e instalando nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Cargar nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo "✅ nvm instalado correctamente"
fi

# Instalar Node.js
echo ""
echo "📦 Instalando Node.js v${NODE_VERSION}..."
nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION

# Verificar instalación
NODE_INSTALLED_VERSION=$(node --version)
NPM_INSTALLED_VERSION=$(npm --version)

echo ""
echo "✅ ¡Node.js instalado exitosamente!"
echo "   Node.js: $NODE_INSTALLED_VERSION"
echo "   npm: $NPM_INSTALLED_VERSION"
echo ""
echo "📝 Información:"
echo "   - nvm está en: $HOME/.nvm"
echo "   - Node.js está administrado por nvm"
echo ""
echo "📝 Comandos útiles de nvm:"
echo "   - nvm install <version>  # Instalar una versión"
echo "   - nvm use <version>      # Usar una versión"
echo "   - nvm list               # Listar versiones instaladas"
echo "   - nvm current            # Ver versión actual"
echo ""
echo "⚠️  Si es una instalación nueva, reinicia tu terminal o ejecuta:"
echo "   source ~/.bashrc   # o ~/.zshrc según tu shell"
