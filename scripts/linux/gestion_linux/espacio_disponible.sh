#!/bin/bash

# Script de análisis de espacio en disco
# Muestra uso de discos, carpetas y archivos grandes

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# =========================
#  Funciones
# =========================

show_menu() {
    clear
    show_header "Análisis de Espacio 💾" "Gestión de almacenamiento"
    
    echo -e "${CYAN}Opciones disponibles:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Ver espacio en discos/particiones"
    echo -e "  ${GREEN}2.${NC} Top 10 carpetas más grandes (directorio actual)"
    echo -e "  ${GREEN}3.${NC} Top 20 archivos más grandes (directorio actual)"
    echo -e "  ${GREEN}4.${NC} Analizar carpeta específica"
    echo -e "  ${GREEN}5.${NC} Buscar archivos grandes (>100MB)"
    echo -e "  ${GREEN}6.${NC} Espacio usado por tipo de archivo"
    echo -e "  ${GREEN}7.${NC} Análisis del home (~)"
    echo -e "  ${GREEN}8.${NC} Limpiar cache del sistema (requiere sudo)"
    echo -e "  ${GREEN}9.${NC} Ver inodos disponibles"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
}

show_disk_space() {
    progress "Mostrando espacio en discos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Espacio en sistemas de archivos:${NC}"
    echo ""
    df -h --output=source,fstype,size,used,avail,pcent,target | grep -v "tmpfs\|devtmpfs\|loop" | column -t
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Mostrar alertas si algún disco está >90%
    local high_usage=$(df -h | awk 'NR>1 && $5+0 > 90 {print $6, $5}' | grep -v "tmpfs\|devtmpfs")
    if [[ -n "$high_usage" ]]; then
        warning "⚠️  Discos con uso >90%:"
        echo "$high_usage"
        echo ""
    fi
}

top_directories() {
    local target_dir="${1:-.}"
    
    progress "Analizando carpetas en $(realpath "$target_dir")..."
    echo ""
    info "Esto puede tardar unos segundos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Top 10 carpetas más grandes:${NC}"
    echo ""
    
    du -h --max-depth=1 "$target_dir" 2>/dev/null | sort -rh | head -11 | awk '{printf "%-10s %s\n", $1, $2}'
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

top_files() {
    local target_dir="${1:-.}"
    
    progress "Buscando archivos grandes en $(realpath "$target_dir")..."
    echo ""
    info "Esto puede tardar unos segundos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Top 20 archivos más grandes:${NC}"
    echo ""
    
    find "$target_dir" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -20 | awk '{printf "%-10s %s\n", $1, $2}'
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

analyze_directory() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce la ruta de la carpeta \(Enter para actual\): ${NC})" dir_path
    dir_path="${dir_path:-.}"
    
    if [[ ! -d "$dir_path" ]]; then
        error "La carpeta '$dir_path' no existe"
        return 1
    fi
    
    echo ""
    progress "Analizando $(realpath "$dir_path")..."
    echo ""
    
    # Tamaño total
    local total_size=$(du -sh "$dir_path" 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}Tamaño total:${NC} $total_size"
    echo ""
    
    # Número de archivos y carpetas
    local num_files=$(find "$dir_path" -type f 2>/dev/null | wc -l)
    local num_dirs=$(find "$dir_path" -type d 2>/dev/null | wc -l)
    echo -e "${CYAN}Archivos:${NC} $num_files"
    echo -e "${CYAN}Carpetas:${NC} $num_dirs"
    echo ""
    
    # Top carpetas
    echo -e "${BOLD}Top 5 subcarpetas:${NC}"
    du -h --max-depth=1 "$dir_path" 2>/dev/null | sort -rh | head -6 | tail -5 | awk '{printf "  %-10s %s\n", $1, $2}'
    echo ""
}

find_large_files() {
    echo ""
    read -p "$(echo -e ${CYAN}Tamaño mínimo en MB \(Enter para 100MB\): ${NC})" min_size
    min_size="${min_size:-100}"
    
    read -p "$(echo -e ${CYAN}Directorio de búsqueda \(Enter para home\): ${NC})" search_dir
    search_dir="${search_dir:-$HOME}"
    
    if [[ ! -d "$search_dir" ]]; then
        error "El directorio '$search_dir' no existe"
        return 1
    fi
    
    echo ""
    progress "Buscando archivos >${min_size}MB en $search_dir..."
    echo ""
    info "Esto puede tardar varios minutos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    
    find "$search_dir" -type f -size +${min_size}M -exec du -h {} + 2>/dev/null | sort -rh | head -30 | awk '{printf "%-10s %s\n", $1, $2}'
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

space_by_type() {
    local target_dir="${1:-.}"
    
    echo ""
    progress "Analizando espacio por tipo de archivo en $(realpath "$target_dir")..."
    echo ""
    info "Esto puede tardar unos segundos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Espacio usado por extensión:${NC}"
    echo ""
    
    # Buscar y agrupar por extensión
    find "$target_dir" -type f 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10 | while read count ext; do
        local size=$(find "$target_dir" -type f -name "*.$ext" -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}')
        printf "%-10s  %-8s  %s archivos\n" "$ext" "$size" "$count"
    done
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

analyze_home() {
    progress "Analizando directorio home ($HOME)..."
    echo ""
    info "Esto puede tardar unos segundos..."
    echo ""
    
    # Tamaño total
    local total_size=$(du -sh "$HOME" 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}Tamaño total de home:${NC} $total_size"
    echo ""
    
    echo -e "${BOLD}Top 10 carpetas en home:${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    du -h --max-depth=1 "$HOME" 2>/dev/null | sort -rh | head -11 | tail -10 | awk '{printf "%-10s %s\n", $1, $2}'
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Carpetas comunes que suelen ocupar espacio
    echo -e "${CYAN}Carpetas comunes de caché:${NC}"
    [[ -d "$HOME/.cache" ]] && echo "  ~/.cache: $(du -sh "$HOME/.cache" 2>/dev/null | awk '{print $1}')"
    [[ -d "$HOME/.local" ]] && echo "  ~/.local: $(du -sh "$HOME/.local" 2>/dev/null | awk '{print $1}')"
    [[ -d "$HOME/.npm" ]] && echo "  ~/.npm: $(du -sh "$HOME/.npm" 2>/dev/null | awk '{print $1}')"
    [[ -d "$HOME/.cargo" ]] && echo "  ~/.cargo: $(du -sh "$HOME/.cargo" 2>/dev/null | awk '{print $1}')"
    [[ -d "$HOME/.vscode" ]] && echo "  ~/.vscode: $(du -sh "$HOME/.vscode" 2>/dev/null | awk '{print $1}')"
    echo ""
}

clean_cache() {
    echo ""
    warning "Esta opción limpiará cachés del sistema y requiere permisos sudo"
    echo ""
    
    if ! confirm "¿Deseas continuar?" "n"; then
        info "Operación cancelada"
        return 0
    fi
    
    echo ""
    progress "Limpiando cachés..."
    echo ""
    
    # Espacio antes
    local before=$(df -h / | awk 'NR==2 {print $4}')
    
    # Limpiar apt cache
    if command -v apt-get &>/dev/null; then
        info "Limpiando caché de apt..."
        sudo apt-get clean 2>/dev/null || true
        sudo apt-get autoclean 2>/dev/null || true
    fi
    
    # Limpiar journalctl
    if command -v journalctl &>/dev/null; then
        info "Limpiando logs antiguos..."
        sudo journalctl --vacuum-time=7d 2>/dev/null || true
    fi
    
    # Limpiar cache de usuario
    info "Limpiando caché de usuario..."
    [[ -d "$HOME/.cache" ]] && rm -rf "$HOME/.cache/"* 2>/dev/null || true
    
    # Limpiar thumbnails
    [[ -d "$HOME/.thumbnails" ]] && rm -rf "$HOME/.thumbnails/"* 2>/dev/null || true
    [[ -d "$HOME/.cache/thumbnails" ]] && rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true
    
    # Espacio después
    local after=$(df -h / | awk 'NR==2 {print $4}')
    
    echo ""
    success "Limpieza completada"
    echo ""
    echo -e "${CYAN}Espacio antes:${NC}  $before"
    echo -e "${CYAN}Espacio después:${NC} $after"
    echo ""
}

show_inodes() {
    progress "Mostrando uso de inodos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Inodos disponibles:${NC}"
    echo ""
    df -i | grep -v "tmpfs\|devtmpfs\|loop" | column -t
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Mostrar alertas si algún fs está >90%
    local high_inodes=$(df -i | awk 'NR>1 && $5+0 > 90 {print $6, $5}' | grep -v "tmpfs\|devtmpfs")
    if [[ -n "$high_inodes" ]]; then
        warning "⚠️  Sistemas de archivos con >90% de inodos usados:"
        echo "$high_inodes"
        echo ""
    fi
}

# =========================
#  Main Loop
# =========================

main() {
    while true; do
        show_menu
        
        read -p "$(echo -e ${YELLOW}Selecciona una opción: ${NC})" option
        
        case $option in
            1)
                show_disk_space
                ;;
            2)
                top_directories
                ;;
            3)
                top_files
                ;;
            4)
                analyze_directory
                ;;
            5)
                find_large_files
                ;;
            6)
                space_by_type
                ;;
            7)
                analyze_home
                ;;
            8)
                clean_cache
                ;;
            9)
                show_inodes
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
