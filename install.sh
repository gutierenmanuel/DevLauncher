#!/bin/bash
# Script de instalación global para los scripts de desarrollo
# Configura el PATH y crea alias para usar los scripts desde cualquier lugar

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Obtener directorio del proyecto
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Instalador Global de Scripts de Desarrollo 🚀           ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detectar shell
SHELL_RC=""
SHELL_NAME=""

if [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
    SHELL_RC="$HOME/.zshrc"
else
    # Intentar detectar
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_NAME="bash"
        SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        SHELL_NAME="zsh"
        SHELL_RC="$HOME/.zshrc"
    else
        echo -e "${RED}✗ No se pudo detectar el shell${NC}"
        echo -e "${YELLOW}  Edita manualmente tu archivo de configuración del shell${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Shell detectado: $SHELL_NAME${NC}"
echo -e "${GREEN}✓ Archivo de configuración: $SHELL_RC${NC}"
echo ""

# Verificar si ya está instalado
if grep -q "# Scripts Development Launcher" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Ya existe una instalación previa${NC}"
    echo -ne "${YELLOW}¿Deseas reinstalar? (s/n): ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[sS]$ ]]; then
        echo -e "${BLUE}Instalación cancelada${NC}"
        exit 0
    fi
    
    # Remover instalación anterior
    echo -e "${CYAN}→ Removiendo instalación anterior...${NC}"
    sed -i '/# Scripts Development Launcher/,/# End Scripts Development Launcher/d' "$SHELL_RC"
fi

# Agregar configuración al shell
echo -e "${CYAN}→ Agregando configuración al $SHELL_RC...${NC}"

cat >> "$SHELL_RC" << EOF

# Scripts Development Launcher
# Agregado automáticamente por install.sh
export DEVSCRIPTS_ROOT="$SCRIPT_ROOT"
export PATH="\$PATH:\$DEVSCRIPTS_ROOT"

# Alias para el lanzador
alias devlauncher="\$DEVSCRIPTS_ROOT/launcher.sh"
alias dl="devlauncher"

# Alias para scripts comunes
alias dev-build="\$DEVSCRIPTS_ROOT/scripts/linux/build/build.sh"
alias dev-start="\$DEVSCRIPTS_ROOT/scripts/linux/dev/dev.sh"
alias dev-init-frontend="\$DEVSCRIPTS_ROOT/scripts/linux/inicializar_repos/init_frontend_project.sh"
alias dev-init-go="\$DEVSCRIPTS_ROOT/scripts/linux/inicializar_repos/init_go_project.sh"
alias dev-init-wails="\$DEVSCRIPTS_ROOT/scripts/linux/inicializar_repos/init_wails_project.sh"

# Función para ejecutar scripts directamente
devscript() {
    if [ -z "\$1" ]; then
        echo "Uso: devscript <nombre_script>"
        echo "Ejemplo: devscript dev.sh"
        return 1
    fi
    
    local script=\$(find "\$DEVSCRIPTS_ROOT/scripts" -type f -name "\$1" ! -path "*/lib/*" | head -n1)
    
    if [ -z "\$script" ]; then
        echo "Script no encontrado: \$1"
        return 1
    fi
    
    echo "Ejecutando: \$script"
    bash "\$script" "\${@:2}"
}

# Autocompletado para devscript
if [ -n "\$BASH_VERSION" ]; then
    _devscript_complete() {
        local cur=\${COMP_WORDS[COMP_CWORD]}
        local scripts=\$(find "\$DEVSCRIPTS_ROOT/scripts" -type f -name "*.sh" ! -path "*/lib/*" -exec basename {} \; | sort)
        COMPREPLY=(\$(compgen -W "\$scripts" -- \$cur))
    }
    complete -F _devscript_complete devscript
fi

# End Scripts Development Launcher
EOF

echo -e "${GREEN}✓ Configuración agregada exitosamente${NC}"
echo ""

# Instrucciones finales
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Instalación completada!${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Para activar los cambios, ejecuta:${NC}"
echo -e "   ${YELLOW}source $SHELL_RC${NC}"
echo ""
echo -e "${CYAN}O simplemente cierra y abre una nueva terminal.${NC}"
echo ""
echo -e "${PURPLE}Comandos disponibles:${NC}"
echo ""
echo -e "  ${GREEN}devlauncher${NC} o ${GREEN}dl${NC}"
echo -e "    ${GRAY}Abre el lanzador interactivo de scripts${NC}"
echo ""
echo -e "  ${GREEN}devscript <nombre>${NC}"
echo -e "    ${GRAY}Ejecuta un script por nombre${NC}"
echo -e "    ${GRAY}Ejemplo: devscript dev.sh${NC}"
echo ""
echo -e "  ${GREEN}Alias directos:${NC}"
echo -e "    ${CYAN}dev-build${NC}         - Compilar proyecto"
echo -e "    ${CYAN}dev-start${NC}         - Iniciar servidor de desarrollo"
echo -e "    ${CYAN}dev-init-frontend${NC} - Crear proyecto frontend"
echo -e "    ${CYAN}dev-init-go${NC}       - Crear proyecto Go"
echo -e "    ${CYAN}dev-init-wails${NC}    - Crear proyecto Wails"
echo ""
echo -e "${GREEN}🎉 ¡Disfruta de tus scripts desde cualquier lugar!${NC}"
echo ""
