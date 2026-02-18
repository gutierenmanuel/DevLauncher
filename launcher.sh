#!/bin/bash
# Lanzador Universal de Scripts de Desarrollo (Linux/macOS)
# Navegación jerárquica: Carpeta → Script

# Colores
Green='\033[32m'
Blue='\033[34m'
Yellow='\033[33m'
Red='\033[31m'
Purple='\033[35m'
Cyan='\033[36m'
Gray='\033[90m'
DimGray='\033[2;37m'
Bold='\033[1m'
NC='\033[0m'

# Box drawing characters
BoxTL="╔"
BoxTR="╗"
BoxBL="╚"
BoxBR="╝"
BoxH="═"
BoxV="║"
BoxML="╠"
BoxMR="╣"
BoxSep="─"

# Obtener el directorio raíz del proyecto
ScriptRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ScriptsDir="$ScriptRoot/scripts"
StaticDir="$ScriptRoot/static"

# ==========================================
# FUNCIONES DEL LANZADOR
# ==========================================

# Función para limpiar pantalla
clear_screen() {
    clear
}

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
    
    if [ ! -f "$script_path" ]; then
        echo "Sin descripción"
        return
    fi
    
    local desc=$(head -n 5 "$script_path" 2>/dev/null | grep -E "^\s*#\s*(Script|Descripción|Description)" | head -n1 | sed -E 's/^\s*#\s*//' | sed -E 's/(Script|Descripción|Description):\s*//' | xargs)
    
    if [ -z "$desc" ]; then
        local filename=$(basename "$script_path" | sed 's/\.[^.]*$//')
        desc=$(echo "$filename" | tr '_' ' ')
    fi
    
    echo "$desc"
}

# Listar categorías disponibles
list_categories() {
    local platform="$1"
    local scan_dir="$ScriptsDir/$platform"
    
    if [ ! -d "$scan_dir" ]; then
        return
    fi
    
    find "$scan_dir" -mindepth 1 -maxdepth 1 -type d ! -name "lib" 2>/dev/null | while read -r dir; do
        basename "$dir"
    done | sort
}

# Listar scripts en una categoría
list_scripts_in_category() {
    local platform="$1"
    local category="$2"
    local category_dir="$ScriptsDir/$platform/$category"
    
    if [ ! -d "$category_dir" ]; then
        return
    fi
    
    if [ "$platform" = "linux" ]; then
        find "$category_dir" -type f -name "*.sh" ! -name "example_*" 2>/dev/null | sort
    else
        find "$category_dir" -type f \( -name "*.ps1" -o -name "*.bat" \) 2>/dev/null | sort
    fi
}

# Contar scripts en una categoría
count_scripts_in_category() {
    local platform="$1"
    local category="$2"
    list_scripts_in_category "$platform" "$category" | wc -l | tr -d ' '
}

# Mostrar encabezado
show_header() {
    local breadcrumb="${1:-}"
    
    echo ""
    
    # Cargar ASCII art desde archivo
    local ascii_file="$StaticDir/asciiart.txt"
    if [ -f "$ascii_file" ]; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "Dev.*Launcher"; then
                echo -e "${Cyan}${line}${NC}"
            else
                echo -e "${Purple}${line}${NC}"
            fi
        done < "$ascii_file"
    else
        # Fallback si no existe el archivo
        echo -e "${Purple}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
        echo -e "${Purple}${BoxV}  🚀 Lanzador Universal de Scripts                         ${BoxV}${NC}"
        echo -e "${Purple}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
    fi
    
    # Mostrar breadcrumb si se proporciona
    if [ -n "$breadcrumb" ]; then
        echo ""
        echo -e "${DimGray}┌─ $breadcrumb${NC}"
    fi
    
    echo ""
}

# Detectar plataforma
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "linux" ;;
        CYGWIN*)    echo "win" ;;
        MINGW*)     echo "win" ;;
        MSYS*)      echo "win" ;;
        *)          echo "linux" ;;
    esac
}

# Menú de categorías
show_category_menu() {
    local platform="$1"
    
    clear_screen
    show_header "Inicio"
    
    echo -e "${DimGray}→ Escaneando categorías...${NC}"
    echo ""
    
    local -a valid_categories=()
    local -a valid_counts=()
    local -a valid_icons=()
    local -a valid_descriptions=()
    
    while IFS= read -r category; do
        if [ -n "$category" ]; then
            local count=$(count_scripts_in_category "$platform" "$category")
            if [ "$count" -gt 0 ]; then
                valid_categories+=("$category")
                valid_counts+=("$count")
                valid_icons+=("$(get_category_icon "$category")")
                valid_descriptions+=("$(get_category_description "$category")")
            fi
        fi
    done < <(list_categories "$platform")
    
    if [ ${#valid_categories[@]} -eq 0 ]; then
        echo -e "${Red}✗ No se encontraron categorías${NC}"
        return
    fi
    
    # Box superior
    echo -e "${Cyan}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
    echo -e "${Cyan}${BoxV}${NC} ${Yellow}${Bold}Selecciona una categoría${NC}$(printf '%*s' 31)${Cyan}${BoxV}${NC}"
    echo -e "${Cyan}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
    echo ""
    
    local i=1
    for idx in "${!valid_categories[@]}"; do
        echo -e "  ${Cyan}${Bold}[$i]${NC} ${valid_icons[$idx]}  ${Bold}${valid_categories[$idx]}${NC}"
        echo -e "      ${DimGray}${BoxSep}${BoxSep}${NC} ${Gray}${valid_descriptions[$idx]}${NC}"
        local script_word="script"
        [ "${valid_counts[$idx]}" != "1" ] && script_word="scripts"
        echo -e "      ${DimGray}${BoxSep}${BoxSep}${NC} ${DimGray}${valid_counts[$idx]} $script_word disponibles${NC}"
        if [ $i -lt ${#valid_categories[@]} ]; then
            echo ""
        fi
        ((i++))
    done
    
    echo ""
    echo -e "${DimGray}$(printf '%*s' 60 | tr ' ' "${BoxSep}")${NC}"
    echo -e "  ${Cyan}${Bold}[0]${NC} ${Red}Salir${NC}"
    echo ""
    
    echo -ne "${Yellow}▶${NC} Opción: "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#valid_categories[@]} ]; then
        local idx=$((choice - 1))
        show_script_menu "$platform" "${valid_categories[$idx]}"
    elif [ "$choice" = "0" ]; then
        echo ""
        echo -e "${Yellow}¡Hasta luego!${NC}"
        echo ""
    else
        echo ""
        echo -e "${Red}✗ Opción inválida${NC}"
        sleep 1
        show_category_menu "$platform"
    fi
}

# Menú de scripts dentro de una categoría
show_script_menu() {
    local platform="$1"
    local category="$2"
    
    clear_screen
    show_header "Inicio > $category"
    
    echo ""
    local icon=$(get_category_icon "$category")
    
    local -a script_paths=()
    local -a script_names=()
    local -a script_descriptions=()
    
    while IFS= read -r script_path; do
        if [ -f "$script_path" ]; then
            script_paths+=("$script_path")
            script_names+=("$(basename "$script_path")")
            script_descriptions+=("$(get_script_description "$script_path")")
        fi
    done < <(list_scripts_in_category "$platform" "$category")
    
    if [ ${#script_paths[@]} -eq 0 ]; then
        echo -e "${Red}✗ No se encontraron scripts en esta categoría${NC}"
        sleep 2
        show_category_menu "$platform"
        return
    fi
    
    local count=${#script_paths[@]}
    local script_word="script"
    [ "$count" != "1" ] && script_word="scripts"
    
    # Box superior
    echo -e "${Cyan}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
    local category_len=${#category}
    local padding=$((50 - category_len))
    printf "${Cyan}${BoxV}${NC} $icon  ${Yellow}${Bold}%s${NC}%${padding}s${Cyan}${BoxV}${NC}\n" "$category" ""
    echo -e "${Cyan}${BoxML}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxMR}${NC}"
    local count_text="$count $script_word disponible"
    [ "$count" != "1" ] && count_text="${count_text}s"
    local count_len=${#count_text}
    padding=$((55 - count_len))
    printf "${Cyan}${BoxV}${NC} ${DimGray}%s${NC}%${padding}s${Cyan}${BoxV}${NC}\n" "$count_text" ""
    echo -e "${Cyan}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
    echo ""
    
    local i=1
    for idx in "${!script_names[@]}"; do
        echo -e "  ${Cyan}${Bold}[$i]${NC} ${Bold}${script_names[$idx]}${NC}"
        if [ -n "${script_descriptions[$idx]}" ]; then
            echo -e "      ${DimGray}${BoxSep}${BoxSep}${NC} ${Gray}${script_descriptions[$idx]}${NC}"
        fi
        if [ $i -lt ${#script_names[@]} ]; then
            echo ""
        fi
        ((i++))
    done
    
    echo ""
    echo -e "${DimGray}$(printf '%*s' 60 | tr ' ' "${BoxSep}")${NC}"
    echo -e "  ${Cyan}${Bold}[.]${NC} ${Yellow}Volver atrás${NC}"
    echo -e "  ${Cyan}${Bold}[0]${NC} ${Red}Salir${NC}"
    echo ""
    
    echo -ne "${Yellow}▶${NC} Opción: "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#script_paths[@]} ]; then
        local idx=$((choice - 1))
        clear_screen
        execute_script "${script_paths[$idx]}"
        
        echo ""
        echo -ne "${Yellow}▶${NC} ¿Ejecutar otro script? ${DimGray}(s/N)${NC}: "
        read -r response
        if [[ "$response" =~ ^[sS]$ ]]; then
            show_script_menu "$platform" "$category"
        else
            show_category_menu "$platform"
        fi
    elif [ "$choice" = "." ]; then
        show_category_menu "$platform"
    elif [ "$choice" = "0" ]; then
        echo ""
        echo -e "${Yellow}¡Hasta luego!${NC}"
        echo ""
    else
        echo ""
        echo -e "${Red}✗ Opción inválida${NC}"
        sleep 1
        show_script_menu "$platform" "$category"
    fi
}

# Ejecutar script seleccionado
execute_script() {
    local script_path="$1"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${Red}✗ El script no existe: $script_path${NC}"
        return
    fi
    
    local script_name=$(basename "$script_path")
    
    echo ""
    echo -e "${Cyan}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
    local name_len=${#script_name}
    local padding=$((43 - name_len))
    printf "${Cyan}${BoxV}${NC} ${Purple}⚡ Ejecutando:${NC} ${Bold}%s${NC}%${padding}s${Cyan}${BoxV}${NC}\n" "$script_name" ""
    echo -e "${Cyan}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
    echo ""
    
    local exit_code=0
    local extension="${script_path##*.}"
    
    if [ "$extension" = "sh" ]; then
        chmod +x "$script_path"
        bash "$script_path"
        exit_code=$?
    elif [ "$extension" = "ps1" ]; then
        if command -v pwsh &> /dev/null; then
            pwsh "$script_path"
            exit_code=$?
        elif command -v powershell &> /dev/null; then
            powershell "$script_path"
            exit_code=$?
        else
            echo -e "${Red}✗ PowerShell no está disponible para ejecutar scripts .ps1${NC}"
            exit_code=1
        fi
    elif [ "$extension" = "bat" ]; then
        if command -v cmd.exe &> /dev/null; then
            cmd.exe /c "$script_path"
            exit_code=$?
        else
            echo -e "${Red}✗ cmd.exe no está disponible para ejecutar scripts .bat${NC}"
            exit_code=1
        fi
    fi
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        echo -e "${Green}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
        echo -e "${Green}${BoxV}${NC} ${Green}✓ Script completado exitosamente${NC}$(printf '%*s' 24)${Green}${BoxV}${NC}"
        echo -e "${Green}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
    else
        local exit_len=${#exit_code}
        local padding=$((19 - exit_len))
        echo -e "${Red}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
        printf "${Red}${BoxV}${NC} ${Red}✗ El script falló con código de salida: %s${NC}%${padding}s${Red}${BoxV}${NC}\n" "$exit_code" ""
        echo -e "${Red}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
    fi
}

# Listar todos los scripts (modo plano)
list_all_scripts() {
    local platform="$1"
    
    show_header "Inicio > Lista completa"
    
    echo -e "${DimGray}→ Plataforma: $platform${NC}"
    echo ""
    
    local total_scripts=0
    local valid_category_count=0
    
    while IFS= read -r category; do
        if [ -n "$category" ]; then
            local count=$(count_scripts_in_category "$platform" "$category")
            if [ "$count" -gt 0 ]; then
                echo ""
                local icon=$(get_category_icon "$category")
                local desc=$(get_category_description "$category")
                
                local category_len=${#category}
                local padding=$((50 - category_len))
                echo -e "${Cyan}${BoxTL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxTR}${NC}"
                printf "${Cyan}${BoxV}${NC} $icon  ${Yellow}${Bold}%s${NC}%${padding}s${Cyan}${BoxV}${NC}\n" "$category" ""
                echo -e "${Cyan}${BoxBL}$(printf '%*s' 58 | tr ' ' "${BoxH}")${BoxBR}${NC}"
                echo ""
                
                while IFS= read -r script_path; do
                    if [ -f "$script_path" ]; then
                        local filename=$(basename "$script_path")
                        local description=$(get_script_description "$script_path")
                        echo -e "  ${Cyan}•${NC} ${Bold}$filename${NC}"
                        if [ -n "$description" ]; then
                            echo -e "    ${DimGray}${BoxSep}${BoxSep}${NC} ${Gray}$description${NC}"
                        fi
                    fi
                done < <(list_scripts_in_category "$platform" "$category")
                
                total_scripts=$((total_scripts + count))
                ((valid_category_count++))
            fi
        fi
    done < <(list_categories "$platform")
    
    echo ""
    echo -e "${DimGray}$(printf '%*s' 60 | tr ' ' "${BoxSep}")${NC}"
    local category_word="categoría"
    [ "$valid_category_count" != "1" ] && category_word="categorías"
    echo -e "${DimGray}Total: $total_scripts scripts en $valid_category_count $category_word${NC}"
    echo ""
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

main() {
    show_header
    
    # Detectar plataforma
    local platform=$(detect_platform)
    
    echo -e "${Gray}Plataforma: $platform | Directorio: $ScriptsDir/$platform${NC}"
    echo ""
    
    # Parsear argumentos
    if [ $# -eq 0 ]; then
        show_category_menu "$platform"
    elif [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
        list_all_scripts "$platform"
    elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
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
    else
        echo -e "${Red}✗ Opción desconocida: $1${NC}"
        echo "Usa --help para ver las opciones disponibles"
    fi
}

# Ejecutar
main "$@"
