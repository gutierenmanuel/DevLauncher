#!/bin/bash
# Lanzador Universal de Scripts de Desarrollo
# Permite ejecutar cualquier script desde cualquier ubicación

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Obtener el directorio raíz del proyecto (donde está el launcher)
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_ROOT/scripts"

# Cargar librería común
source "$SCRIPTS_DIR/lib/common.sh"

# ==========================================
# FUNCIONES DEL LANZADOR
# ==========================================

# Extraer descripción de un script (del comentario en la línea 2 o 3)
get_script_description() {
    local script_path="$1"
    local desc=""
    
    # Intentar extraer descripción de las primeras líneas
    desc=$(head -n 5 "$script_path" | grep -E "^#[[:space:]]*(Script|Descripción|Description)" | head -n1 | sed 's/^#[[:space:]]*//')
    
    # Si no encuentra, usar el nombre del directorio como pista
    if [ -z "$desc" ]; then
        local category=$(dirname "$script_path" | xargs basename)
        desc="Script de $category"
    fi
    
    echo "$desc"
}

# Escanear y listar todos los scripts disponibles
scan_scripts() {
    local platform="$1"  # linux o win
    local scan_dir="$SCRIPTS_DIR/$platform"
    
    # Determinar extensiones según la plataforma
    local extensions
    if [ "$platform" = "linux" ]; then
        extensions=".sh"
    else
        extensions=".ps1|.bat"
    fi
    
    # Buscar scripts (excluyendo lib y ejemplos)
    find "$scan_dir" -type f \( -name "*.sh" -o -name "*.ps1" -o -name "*.bat" \) ! -path "*/lib/*" ! -name "example_*" 2>/dev/null | sort
}

# Categorizar scripts por su ubicación
categorize_scripts() {
    declare -A categories
    local script_path
    
    while IFS= read -r script_path; do
        local rel_path="${script_path#$SCRIPTS_DIR/}"
        local category=$(echo "$rel_path" | cut -d'/' -f2)
        
        if [ -z "${categories[$category]}" ]; then
            categories[$category]="$script_path"
        else
            categories[$category]="${categories[$category]}|$script_path"
        fi
    done
    
    # Imprimir categorías
    for category in "${!categories[@]}"; do
        echo "$category:${categories[$category]}"
    done
}

# Mostrar menú interactivo con fzf si está disponible
show_menu_fzf() {
    local platform="$1"
    
    info "Escaneando scripts disponibles..."
    
    # Preparar lista de scripts con descripción
    local -a scripts=()
    local -a script_paths=()
    local script_path
    
    while IFS= read -r script_path; do
        if [ -f "$script_path" ]; then
            local filename=$(basename "$script_path")
            local rel_path="${script_path#$SCRIPTS_DIR/$platform/}"
            local category=$(dirname "$rel_path")
            local description=$(get_script_description "$script_path")
            
            # Formato: [categoría] nombre - descripción
            scripts+=("[$category] $filename - $description")
            script_paths+=("$script_path")
        fi
    done < <(scan_scripts "$platform")
    
    if [ ${#scripts[@]} -eq 0 ]; then
        error "No se encontraron scripts en $platform"
        return 1
    fi
    
    echo ""
    success "Encontrados ${#scripts[@]} scripts"
    echo ""
    
    # Usar fzf si está disponible
    if command -v fzf &> /dev/null; then
        local selection
        selection=$(printf '%s\n' "${scripts[@]}" | fzf \
            --height=50% \
            --border \
            --prompt="Selecciona un script: " \
            --header="Usa ↑↓ para navegar, Enter para seleccionar, Esc para salir" \
            --preview-window=right:50%:wrap \
            --color=bg+:#2d3748,fg+:#ffffff,hl:#4299e1,hl+:#4299e1)
        
        if [ -n "$selection" ]; then
            # Encontrar el índice del script seleccionado
            local idx=0
            for i in "${!scripts[@]}"; do
                if [ "${scripts[$i]}" = "$selection" ]; then
                    idx=$i
                    break
                fi
            done
            
            execute_script "${script_paths[$idx]}"
        else
            warning "Cancelado por el usuario"
        fi
    else
        # Fallback: menú con select
        show_menu_select "$platform" "${scripts[@]}"
    fi
}

# Menú alternativo con bash select
show_menu_select() {
    local platform="$1"
    shift
    local scripts=("$@")
    
    echo -e "${YELLOW}Selecciona un script:${NC}"
    echo ""
    
    local -a script_paths=()
    while IFS= read -r script_path; do
        script_paths+=("$script_path")
    done < <(scan_scripts "$platform")
    
    # Mostrar menú numerado
    local i=1
    for script in "${scripts[@]}"; do
        echo -e "${CYAN}$i)${NC} $script"
        ((i++))
    done
    echo -e "${CYAN}0)${NC} ${RED}Salir${NC}"
    echo ""
    
    read -p "Opción: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#scripts[@]} ]; then
        local idx=$((choice - 1))
        execute_script "${script_paths[$idx]}"
    elif [ "$choice" = "0" ]; then
        warning "Cancelado"
    else
        error "Opción inválida"
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
    echo -e "${PURPLE}  Ejecutando: ${CYAN}$script_name${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Hacer el script ejecutable si no lo es
    chmod +x "$script_path"
    
    # Ejecutar el script
    if [[ "$script_path" == *.sh ]]; then
        bash "$script_path"
    elif [[ "$script_path" == *.ps1 ]]; then
        pwsh "$script_path" 2>/dev/null || powershell "$script_path"
    elif [[ "$script_path" == *.bat ]]; then
        cmd.exe /c "$script_path"
    fi
    
    local exit_code=$?
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        success "Script completado exitosamente"
    else
        error "El script falló con código de salida: $exit_code"
    fi
    
    return $exit_code
}

# Listar todos los scripts disponibles
list_all_scripts() {
    local platform="$1"
    
    show_header "Scripts Disponibles" "Plataforma: $platform"
    
    local script_path
    local current_category=""
    
    while IFS= read -r script_path; do
        local rel_path="${script_path#$SCRIPTS_DIR/$platform/}"
        local category=$(dirname "$rel_path")
        local filename=$(basename "$script_path")
        local description=$(get_script_description "$script_path")
        
        # Mostrar categoría si cambió
        if [ "$category" != "$current_category" ]; then
            echo ""
            echo -e "${PURPLE}▶ $category${NC}"
            echo -e "${GRAY}$( printf '─%.0s' {1..60} )${NC}"
            current_category="$category"
        fi
        
        echo -e "  ${GREEN}•${NC} ${CYAN}$filename${NC}"
        echo -e "    ${GRAY}$description${NC}"
    done < <(scan_scripts "$platform")
    
    echo ""
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

main() {
    show_header "🚀 Lanzador Universal de Scripts" "Gestiona tus scripts de desarrollo fácilmente"
    
    # Detectar plataforma
    local platform="linux"
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        platform="win"
    fi
    
    info "Plataforma detectada: $platform"
    
    # Parsear argumentos
    case "${1:-}" in
        -l|--list)
            list_all_scripts "$platform"
            ;;
        -h|--help)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  (sin opciones)  Mostrar menú interactivo"
            echo "  -l, --list      Listar todos los scripts disponibles"
            echo "  -h, --help      Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0              # Menú interactivo"
            echo "  $0 --list       # Lista de scripts"
            echo ""
            ;;
        "")
            show_menu_fzf "$platform"
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
