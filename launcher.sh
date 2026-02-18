#!/bin/bash
# Lanzador Universal de Scripts de Desarrollo
# Navegación jerárquica: Carpeta → Script

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# Obtener el directorio raíz del proyecto
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_ROOT/scripts"

# Cargar librería común
source "$SCRIPTS_DIR/lib/common.sh"

# ==========================================
# FUNCIONES DEL LANZADOR
# ==========================================

# Obtener icono para cada categoría
get_category_icon() {
    local category="$1"
    case "$category" in
        build) echo "🏗️" ;;
        dev) echo "💻" ;;
        inicializar_repos) echo "🆕" ;;
        instaladores) echo "📦" ;;
        utils|utilidades) echo "🔧" ;;
        *) echo "📁" ;;
    esac
}

# Obtener descripción de categoría
get_category_description() {
    local category="$1"
    case "$category" in
        build) echo "Scripts de compilación y construcción" ;;
        dev) echo "Scripts de desarrollo y servidor" ;;
        inicializar_repos) echo "Inicializadores de proyectos nuevos" ;;
        instaladores) echo "Instaladores de herramientas y dependencias" ;;
        utils|utilidades) echo "Utilidades y herramientas varias" ;;
        *) echo "Scripts varios" ;;
    esac
}

# Extraer descripción de un script
get_script_description() {
    local script_path="$1"
    local desc=""
    
    # Buscar línea con descripción (líneas 2-5)
    desc=$(head -n 5 "$script_path" | grep -E "^#[[:space:]]*(Script|Descripción|Description)" | head -n1 | sed 's/^#[[:space:]]*//' | sed 's/Script[[:space:]]*//')
    
    if [ -z "$desc" ]; then
        local filename=$(basename "$script_path" .sh)
        desc="${filename//_/ }"
    fi
    
    echo "$desc"
}

# Listar categorías disponibles
list_categories() {
    local platform="$1"
    local scan_dir="$SCRIPTS_DIR/$platform"
    
    find "$scan_dir" -mindepth 1 -maxdepth 1 -type d ! -name "lib" | sort | while read -r dir; do
        basename "$dir"
    done
}

# Listar scripts en una categoría
list_scripts_in_category() {
    local platform="$1"
    local category="$2"
    local category_dir="$SCRIPTS_DIR/$platform/$category"
    
    if [ "$platform" = "linux" ]; then
        find "$category_dir" -type f -name "*.sh" ! -name "example_*" | sort
    else
        find "$category_dir" -type f \( -name "*.ps1" -o -name "*.bat" \) | sort
    fi
}

# Contar scripts en una categoría
count_scripts_in_category() {
    local platform="$1"
    local category="$2"
    list_scripts_in_category "$platform" "$category" | wc -l
}

# Menú de categorías
show_category_menu() {
    local platform="$1"
    
    info "Escaneando categorías disponibles..."
    echo ""
    
    local -a categories=()
    local -a category_displays=()
    
    while IFS= read -r category; do
        if [ -n "$category" ]; then
            local count=$(count_scripts_in_category "$platform" "$category")
            if [ "$count" -gt 0 ]; then
                categories+=("$category")
                local icon=$(get_category_icon "$category")
                local desc=$(get_category_description "$category")
                category_displays+=("$icon  $category - $desc ($count scripts)")
            fi
        fi
    done < <(list_categories "$platform")
    
    if [ ${#categories[@]} -eq 0 ]; then
        error "No se encontraron categorías con scripts"
        return 1
    fi
    
    success "Encontradas ${#categories[@]} categorías"
    echo ""
    
    # Usar fzf si está disponible
    if command -v fzf &> /dev/null; then
        local selection
        selection=$(printf '%s\n' "${category_displays[@]}" | fzf \
            --height=60% \
            --border \
            --prompt="📁 Selecciona una categoría: " \
            --header="↑↓ Navegar | Enter Seleccionar | Esc Salir" \
            --color=bg+:#2d3748,fg+:#ffffff,hl:#4299e1,hl+:#4299e1)
        
        if [ -n "$selection" ]; then
            # Extraer nombre de categoría
            local selected_category=$(echo "$selection" | sed -E 's/^[^ ]+ +([^ ]+) -.*/\1/')
            show_script_menu "$platform" "$selected_category"
        else
            warning "Cancelado"
        fi
    else
        show_category_menu_select "$platform" "${categories[@]}"
    fi
}

# Menú de categorías con select
show_category_menu_select() {
    local platform="$1"
    shift
    local categories=("$@")
    
    echo -e "${YELLOW}${BOLD}Selecciona una categoría:${NC}"
    echo ""
    
    local i=1
    for category in "${categories[@]}"; do
        local icon=$(get_category_icon "$category")
        local desc=$(get_category_description "$category")
        local count=$(count_scripts_in_category "$platform" "$category")
        echo -e "${CYAN}$i)${NC} $icon  ${BOLD}$category${NC}"
        echo -e "   ${GRAY}$desc ($count scripts)${NC}"
        ((i++))
    done
    echo -e "${CYAN}0)${NC} ${RED}← Salir${NC}"
    echo ""
    
    read -p "Opción: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
        local idx=$((choice - 1))
        show_script_menu "$platform" "${categories[$idx]}"
    elif [ "$choice" = "0" ]; then
        warning "Cancelado"
    else
        error "Opción inválida"
    fi
}

# Menú de scripts dentro de una categoría
show_script_menu() {
    local platform="$1"
    local category="$2"
    
    echo ""
    local icon=$(get_category_icon "$category")
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    printf "${PURPLE}║${NC} $icon  %-52s ${PURPLE}║${NC}\n" "$category"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local -a scripts=()
    local -a script_paths=()
    local -a script_displays=()
    
    while IFS= read -r script_path; do
        if [ -f "$script_path" ]; then
            local filename=$(basename "$script_path")
            local description=$(get_script_description "$script_path")
            
            scripts+=("$filename")
            script_paths+=("$script_path")
            script_displays+=("$filename - $description")
        fi
    done < <(list_scripts_in_category "$platform" "$category")
    
    if [ ${#scripts[@]} -eq 0 ]; then
        error "No se encontraron scripts en esta categoría"
        return 1
    fi
    
    # Usar fzf si está disponible
    if command -v fzf &> /dev/null; then
        local selection
        selection=$(printf '%s\n' "${script_displays[@]}" | fzf \
            --height=60% \
            --border \
            --prompt="📄 Selecciona un script: " \
            --header="↑↓ Navegar | Enter Ejecutar | Esc Volver" \
            --color=bg+:#2d3748,fg+:#ffffff,hl:#4299e1,hl+:#4299e1)
        
        if [ -n "$selection" ]; then
            # Encontrar el índice
            local idx=0
            for i in "${!script_displays[@]}"; do
                if [ "${script_displays[$i]}" = "$selection" ]; then
                    idx=$i
                    break
                fi
            done
            
            execute_script "${script_paths[$idx]}"
            
            # Preguntar si quiere ejecutar otro
            echo ""
            if confirm "¿Ejecutar otro script de esta categoría?" "n"; then
                show_script_menu "$platform" "$category"
            else
                show_category_menu "$platform"
            fi
        else
            show_category_menu "$platform"
        fi
    else
        show_script_menu_select "$platform" "$category" "${script_paths[@]}"
    fi
}

# Menú de scripts con select
show_script_menu_select() {
    local platform="$1"
    local category="$2"
    shift 2
    local script_paths=("$@")
    
    echo -e "${YELLOW}${BOLD}Selecciona un script:${NC}"
    echo ""
    
    local i=1
    for script_path in "${script_paths[@]}"; do
        local filename=$(basename "$script_path")
        local description=$(get_script_description "$script_path")
        echo -e "${CYAN}$i)${NC} ${BOLD}$filename${NC}"
        echo -e "   ${GRAY}$description${NC}"
        ((i++))
    done
    echo -e "${CYAN}b)${NC} ${YELLOW}← Volver a categorías${NC}"
    echo -e "${CYAN}0)${NC} ${RED}← Salir${NC}"
    echo ""
    
    read -p "Opción: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#script_paths[@]} ]; then
        local idx=$((choice - 1))
        execute_script "${script_paths[$idx]}"
        
        echo ""
        if confirm "¿Ejecutar otro script?" "n"; then
            show_script_menu_select "$platform" "$category" "${script_paths[@]}"
        else
            show_category_menu "$platform"
        fi
    elif [ "$choice" = "b" ] || [ "$choice" = "B" ]; then
        show_category_menu "$platform"
    elif [ "$choice" = "0" ]; then
        warning "Saliendo..."
    else
        error "Opción inválida"
        sleep 1
        show_script_menu_select "$platform" "$category" "${script_paths[@]}"
    fi
}

# Ejecutar script seleccionado
execute_script() {
    local script_path="$1"
    
    if [ ! -f "$script_path" ]; then
        error "El script no existe: $script_path"
        return 1
    fi
    
    local script_name=$(basename "$script_path")
    
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  Ejecutando: ${CYAN}${BOLD}$script_name${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Hacer ejecutable
    chmod +x "$script_path"
    
    # Ejecutar según extensión
    if [[ "$script_path" == *.sh ]]; then
        bash "$script_path"
    elif [[ "$script_path" == *.ps1 ]]; then
        pwsh "$script_path" 2>/dev/null || powershell "$script_path"
    elif [[ "$script_path" == *.bat ]]; then
        cmd.exe /c "$script_path"
    fi
    
    local exit_code=$?
    
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    if [ $exit_code -eq 0 ]; then
        success "Script completado exitosamente"
    else
        error "El script falló con código de salida: $exit_code"
    fi
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    
    return $exit_code
}

# Listar todos los scripts (modo plano)
list_all_scripts() {
    local platform="$1"
    
    show_header "Scripts Disponibles" "Plataforma: $platform"
    
    local current_category=""
    
    while IFS= read -r category; do
        if [ -n "$category" ]; then
            local count=$(count_scripts_in_category "$platform" "$category")
            if [ "$count" -gt 0 ]; then
                echo ""
                local icon=$(get_category_icon "$category")
                local desc=$(get_category_description "$category")
                echo -e "${PURPLE}$icon  ${BOLD}$category${NC}"
                echo -e "${GRAY}   $desc${NC}"
                echo -e "${GRAY}   $(printf '─%.0s' {1..58})${NC}"
                
                while IFS= read -r script_path; do
                    local filename=$(basename "$script_path")
                    local description=$(get_script_description "$script_path")
                    echo -e "   ${GREEN}•${NC} ${CYAN}$filename${NC}"
                    echo -e "     ${GRAY}$description${NC}"
                done < <(list_scripts_in_category "$platform" "$category")
            fi
        fi
    done < <(list_categories "$platform")
    
    echo ""
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

main() {
    show_header "🚀 Lanzador Universal de Scripts" "Navegación jerárquica: Categoría → Script"
    
    # Detectar plataforma
    local platform="linux"
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        platform="win"
    fi
    
    info "Plataforma detectada: ${BOLD}$platform${NC}"
    echo ""
    
    # Parsear argumentos
    case "${1:-}" in
        -l|--list)
            list_all_scripts "$platform"
            ;;
        -h|--help)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  (sin opciones)  Mostrar menú interactivo jerárquico"
            echo "  -l, --list      Listar todos los scripts organizados"
            echo "  -h, --help      Mostrar esta ayuda"
            echo ""
            echo "Navegación:"
            echo "  1. Selecciona una categoría (build, dev, instaladores, etc.)"
            echo "  2. Selecciona un script dentro de la categoría"
            echo "  3. El script se ejecuta automáticamente"
            echo ""
            echo "Atajos de teclado (con fzf):"
            echo "  ↑/↓           Navegar"
            echo "  Enter         Seleccionar"
            echo "  Esc           Volver/Salir"
            echo ""
            ;;
        "")
            show_category_menu "$platform"
            ;;
        *)
            error "Opción desconocida: $1"
            echo "Usa --help para ver las opciones disponibles"
            exit 1
            ;;
    esac
}

# Ejecutar
main "$@"
