#!/bin/bash

# Script para instalar pnpm en Linux

set -e

echo "🚀 Instalando pnpm"
echo ""

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    echo "   Instálalo primero con: ./scripts/instaladores/instalar_nodejs.sh"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js detectado: $NODE_VERSION"
echo ""

# Verificar si pnpm ya está instalado
if command -v pnpm &> /dev/null; then
    CURRENT_VERSION=$(pnpm --version)
    echo "⚠️  pnpm ya está instalado (versión: $CURRENT_VERSION)"
    echo "   Actualizando..."
fi

# Instalar pnpm usando npm
echo "📦 Instalando pnpm globalmente..."
npm install -g pnpm

# Verificar instalación
PNPM_VERSION=$(pnpm --version)

echo ""
echo "✅ ¡pnpm instalado exitosamente!"
echo "   Versión: $PNPM_VERSION"
echo ""
echo "📝 Comandos básicos de pnpm:"
echo "   - pnpm install           # Instalar dependencias"
echo "   - pnpm add <package>     # Agregar paquete"
echo "   - pnpm remove <package>  # Remover paquete"
echo "   - pnpm run <script>      # Ejecutar script"
echo "   - pnpm update            # Actualizar dependencias"
echo ""
echo "📚 Más info: https://pnpm.io/"
