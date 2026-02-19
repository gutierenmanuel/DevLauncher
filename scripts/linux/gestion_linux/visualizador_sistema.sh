#!/bin/bash

# Script de visualización del sistema
# Muestra información del sistema usando neofetch

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# =========================
#  Funciones
# =========================

check_neofetch() {
    if ! command -v neofetch &>/dev/null; then
        return 1
    fi
    return 0
}

install_neofetch() {
    echo ""
    warning "neofetch no está instalado en el sistema"
    echo ""
    
    if ! confirm "¿Deseas instalar neofetch ahora?" "y"; then
        info "Instalación cancelada"
        return 1
    fi
    
    echo ""
    progress "Instalando neofetch..."
    echo ""
    
    # Detectar el gestor de paquetes
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y neofetch
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y neofetch
    elif command -v yum &>/dev/null; then
        sudo yum install -y neofetch
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm neofetch
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y neofetch
    else
        error "No se pudo detectar un gestor de paquetes compatible"
        echo ""
        info "Instala neofetch manualmente desde: https://github.com/dylanaraps/neofetch"
        return 1
    fi
    
    echo ""
    success "neofetch instalado correctamente"
    echo ""
    
    return 0
}

show_system_info() {
    clear
    show_header "Visualizador del Sistema 🖥️" "Información del sistema"
    
    echo ""
    
    # Verificar si neofetch está instalado
    if ! check_neofetch; then
        if ! install_neofetch; then
            return 1
        fi
    fi
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Ejecutar neofetch
    neofetch
    
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_menu() {
    clear
    show_header "Visualizador del Sistema 🖥️" "Información del sistema"
    
    echo -e "${CYAN}Opciones disponibles:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Ver información del sistema (neofetch)"
    echo -e "  ${GREEN}2.${NC} Ver información completa (neofetch --stdout)"
    echo -e "  ${GREEN}3.${NC} Ver solo información de hardware"
    echo -e "  ${GREEN}4.${NC} Ver información personalizada"
    echo -e "  ${GREEN}5.${NC} Instalar/Reinstalar neofetch"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
}

show_full_info() {
    echo ""
    progress "Mostrando información completa del sistema..."
    echo ""
    
    if ! check_neofetch; then
        if ! install_neofetch; then
            return 1
        fi
    fi
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    neofetch --stdout
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_hardware_info() {
    echo ""
    progress "Mostrando información de hardware..."
    echo ""
    
    if ! check_neofetch; then
        if ! install_neofetch; then
            return 1
        fi
    fi
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    neofetch --off --cpu --gpu --memory --disk --resolution
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_custom_info() {
    echo ""
    echo -e "${CYAN}Opciones de visualización personalizada:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} OS + Kernel + CPU"
    echo -e "  ${GREEN}2.${NC} Memoria + Disco"
    echo -e "  ${GREEN}3.${NC} Uptime + Packages + Shell"
    echo -e "  ${GREEN}4.${NC} Resolución + GPU + DE/WM"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Selecciona una opción: ${NC})" custom_option
    
    if ! check_neofetch; then
        if ! install_neofetch; then
            return 1
        fi
    fi
    
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    
    case $custom_option in
        1)
            neofetch --off --os --kernel --cpu
            ;;
        2)
            neofetch --off --memory --disk
            ;;
        3)
            neofetch --off --uptime --packages --shell
            ;;
        4)
            neofetch --off --resolution --gpu --de --wm
            ;;
        *)
            error "Opción inválida"
            ;;
    esac
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

force_install_neofetch() {
    echo ""
    warning "Esto instalará o reinstalará neofetch"
    echo ""
    
    if ! confirm "¿Deseas continuar?" "y"; then
        info "Operación cancelada"
        return 0
    fi
    
    install_neofetch
}

# =========================
#  Main Loop
# =========================

main() {
    # Si se pasa argumento --direct, mostrar directamente
    if [[ "$1" == "--direct" ]]; then
        show_system_info
        return 0
    fi
    
    while true; do
        show_menu
        
        read -p "$(echo -e ${YELLOW}Selecciona una opción: ${NC})" option
        
        case $option in
            1)
                show_system_info
                ;;
            2)
                show_full_info
                ;;
            3)
                show_hardware_info
                ;;
            4)
                show_custom_info
                ;;
            5)
                force_install_neofetch
                ;;
            0)
                echo ""
                success "¡Hasta luego!"
                exit 0
                ;;
            *)
                echo ""
                error "Opción inválida"
                echo ""
                ;;
        esac
        
        read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
    done
}

main "$@"
