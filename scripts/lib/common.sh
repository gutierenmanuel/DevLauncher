#!/bin/bash
# Librería común para scripts de desarrollo
# Proporciona funciones de utilidad, colores, logging y manejo de errores

# ==========================================
# COLORES Y FORMATO
# ==========================================
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export ORANGE='\033[0;33m'
export GRAY='\033[0;90m'
export BOLD='\033[1m'
export NC='\033[0m'

# ==========================================
# SÍMBOLOS
# ==========================================
export CHECKMARK="✓"
export CROSS="✗"
export ARROW="→"
export BULLET="•"
export WARNING="⚠"
export INFO="ℹ"
export FIRE="🔥"
export PACKAGE="📦"
export ROCKET="🚀"
export WRENCH="🔧"
export GEAR="⚙️"

# ==========================================
# CONFIGURACIÓN DE ERROR HANDLING
# ==========================================
export ERROR_LOG_FILE="${ERROR_LOG_FILE:-/tmp/script-errors-$(date +%Y%m%d).log}"
export DEBUG_MODE="${DEBUG_MODE:-0}"

# ==========================================
# FUNCIONES DE LOGGING
# ==========================================

# Función para logging con timestamp
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$ERROR_LOG_FILE"
    
    if [ "$DEBUG_MODE" = "1" ]; then
        echo -e "${GRAY}[$timestamp] [$level] $message${NC}" >&2
    fi
}

# Mensajes de éxito
success() {
    echo -e "${GREEN}${CHECKMARK} $@${NC}"
    log "SUCCESS" "$@"
}

# Mensajes de información
info() {
    echo -e "${BLUE}${INFO} $@${NC}"
    log "INFO" "$@"
}

# Mensajes de advertencia
warning() {
    echo -e "${YELLOW}${WARNING} $@${NC}"
    log "WARNING" "$@"
}

# Mensajes de error
error() {
    echo -e "${RED}${CROSS} Error: $@${NC}" >&2
    log "ERROR" "$@"
}

# Mensajes de debug (solo se muestran si DEBUG_MODE=1)
debug() {
    if [ "$DEBUG_MODE" = "1" ]; then
        echo -e "${GRAY}[DEBUG] $@${NC}" >&2
    fi
    log "DEBUG" "$@"
}

# Progreso
progress() {
    echo -e "${CYAN}${ARROW} $@${NC}"
}

# ==========================================
# FUNCIÓN DE MANEJO DE ERRORES
# ==========================================

# Función principal de manejo de errores
# Uso: handle_error "CÓDIGO_ERROR" "Descripción del error" ["solución opcional"]
handle_error() {
    local error_code="$1"
    local error_description="$2"
    local custom_solution="$3"
    
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ${CROSS} ERROR DETECTADO                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}${BOLD}Error:${NC} ${error_description}"
    echo -e "${GRAY}Código: ${error_code}${NC}"
    echo ""
    
    # Obtener solución específica o usar la personalizada
    local solution="${custom_solution}"
    if [ -z "$solution" ]; then
        solution=$(get_error_solution "$error_code")
    fi
    
    if [ -n "$solution" ]; then
        echo -e "${YELLOW}${WRENCH} Solución sugerida:${NC}"
        echo -e "   ${solution}"
        echo ""
    fi
    
    # Información adicional de contexto
    echo -e "${GRAY}${INFO} Información adicional:${NC}"
    echo -e "   ${GRAY}${BULLET} Script: ${BASH_SOURCE[2]:-desconocido}${NC}"
    echo -e "   ${GRAY}${BULLET} Línea: ${BASH_LINENO[1]:-desconocido}${NC}"
    echo -e "   ${GRAY}${BULLET} Función: ${FUNCNAME[2]:-main}${NC}"
    echo -e "   ${GRAY}${BULLET} Directorio: $(pwd)${NC}"
    echo -e "   ${GRAY}${BULLET} Usuario: $(whoami)${NC}"
    echo -e "   ${GRAY}${BULLET} Log: ${ERROR_LOG_FILE}${NC}"
    echo ""
    
    # Log detallado
    log "ERROR" "Code: $error_code | Description: $error_description | Script: ${BASH_SOURCE[2]} | Line: ${BASH_LINENO[1]}"
    
    # Mostrar últimas líneas del log si existe
    if [ -f "$ERROR_LOG_FILE" ]; then
        echo -e "${GRAY}Últimos eventos (ver $ERROR_LOG_FILE para más detalles):${NC}"
        tail -n 3 "$ERROR_LOG_FILE" | while read line; do
            echo -e "   ${GRAY}$line${NC}"
        done
        echo ""
    fi
    
    return 1
}

# ==========================================
# SOLUCIONES PREDEFINIDAS POR ERROR
# ==========================================

get_error_solution() {
    local error_code="$1"
    
    case "$error_code" in
        "GO_NOT_FOUND")
            echo "Instala Go desde https://go.dev/dl/ o ejecuta:"
            echo "   ${GREEN}./scripts/linux/instaladores/instalar_go.sh${NC}"
            ;;
        "WAILS_NOT_FOUND")
            echo "Instala Wails ejecutando:"
            echo "   ${GREEN}./scripts/linux/instaladores/instalar_wails.sh${NC}"
            echo "   O manualmente: ${GRAY}go install github.com/wailsapp/wails/v2/cmd/wails@latest${NC}"
            ;;
        "PNPM_NOT_FOUND")
            echo "Instala pnpm ejecutando:"
            echo "   ${GREEN}./scripts/linux/instaladores/instalar_pnpm.sh${NC}"
            echo "   O manualmente: ${GRAY}npm install -g pnpm${NC}"
            ;;
        "NODE_NOT_FOUND")
            echo "Instala Node.js ejecutando:"
            echo "   ${GREEN}./scripts/linux/instaladores/instalar_nodejs.sh${NC}"
            echo "   O descarga desde: https://nodejs.org/"
            ;;
        "NPM_NOT_FOUND")
            echo "NPM debería venir con Node.js. Reinstala Node.js:"
            echo "   ${GREEN}./scripts/linux/instaladores/instalar_nodejs.sh${NC}"
            ;;
        "GIT_NOT_FOUND")
            echo "Instala Git con tu gestor de paquetes:"
            echo "   Ubuntu/Debian: ${GRAY}sudo apt install git${NC}"
            echo "   Fedora: ${GRAY}sudo dnf install git${NC}"
            echo "   Arch: ${GRAY}sudo pacman -S git${NC}"
            ;;
        "DIRECTORY_NOT_FOUND")
            echo "Verifica que estés en el directorio correcto del proyecto"
            echo "   El script espera encontrar ciertos directorios/archivos"
            ;;
        "PERMISSION_DENIED")
            echo "Problema de permisos. Intenta:"
            echo "   ${GRAY}sudo chmod +x script.sh${NC} (para ejecutables)"
            echo "   ${GRAY}sudo chown \$(whoami):\$(whoami) archivo${NC} (para propiedad)"
            ;;
        "BUILD_FAILED")
            echo "El build falló. Verifica:"
            echo "   ${BULLET} Que todas las dependencias estén instaladas"
            echo "   ${BULLET} Que no haya errores de sintaxis en el código"
            echo "   ${BULLET} Los logs anteriores para más detalles"
            ;;
        "NETWORK_ERROR")
            echo "Error de red. Verifica:"
            echo "   ${BULLET} Tu conexión a Internet"
            echo "   ${BULLET} Que no haya firewall bloqueando"
            echo "   ${BULLET} Proxy configurado correctamente (si aplica)"
            ;;
        "PORT_IN_USE")
            echo "El puerto ya está en uso. Intenta:"
            echo "   ${GRAY}lsof -i :PUERTO${NC} para ver qué lo usa"
            echo "   ${GRAY}kill -9 PID${NC} para terminar el proceso"
            echo "   O usa un puerto diferente"
            ;;
        *)
            echo "Error genérico. Revisa los logs y la documentación"
            echo "   Log de errores: ${ERROR_LOG_FILE}"
            ;;
    esac
}

# ==========================================
# VERIFICACIÓN DE DEPENDENCIAS
# ==========================================

# Verificar que un comando exista
# Uso: check_command "comando" "CÓDIGO_ERROR" ["descripción"]
check_command() {
    local cmd="$1"
    local error_code="${2:-COMMAND_NOT_FOUND}"
    local description="${3:-El comando '$cmd' no está disponible}"
    
    debug "Verificando comando: $cmd"
    
    if ! command -v "$cmd" &> /dev/null; then
        handle_error "$error_code" "$description"
        return 1
    fi
    
    return 0
}

# Verificar múltiples comandos a la vez
# Uso: check_commands "cmd1" "cmd2" "cmd3"
check_commands() {
    local failed=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Comando no encontrado: $cmd"
            failed=1
        fi
    done
    
    if [ $failed -eq 1 ]; then
        handle_error "MULTIPLE_COMMANDS_MISSING" "Faltan múltiples dependencias requeridas"
        return 1
    fi
    
    return 0
}

# Verificar que un directorio exista
# Uso: check_directory "/ruta/dir" ["mensaje de error"]
check_directory() {
    local dir="$1"
    local error_msg="${2:-El directorio '$dir' no existe}"
    
    debug "Verificando directorio: $dir"
    
    if [ ! -d "$dir" ]; then
        handle_error "DIRECTORY_NOT_FOUND" "$error_msg"
        return 1
    fi
    
    return 0
}

# Verificar que un archivo exista
# Uso: check_file "/ruta/archivo" ["mensaje de error"]
check_file() {
    local file="$1"
    local error_msg="${2:-El archivo '$file' no existe}"
    
    debug "Verificando archivo: $file"
    
    if [ ! -f "$file" ]; then
        handle_error "FILE_NOT_FOUND" "$error_msg"
        return 1
    fi
    
    return 0
}

# ==========================================
# FUNCIONES DE UTILIDAD
# ==========================================

# Mostrar header de script
show_header() {
    local title="$1"
    local subtitle="${2:-}"
    
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    printf "${PURPLE}║${NC} %-57s ${PURPLE}║${NC}\n" "$title"
    if [ -n "$subtitle" ]; then
        printf "${PURPLE}║${NC} %-57s ${PURPLE}║${NC}\n" "$subtitle"
    fi
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Mostrar versión de un comando
show_version() {
    local cmd="$1"
    local version_flag="${2:---version}"
    
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd $version_flag 2>&1 | head -n1)
        success "$cmd: $version"
    else
        warning "$cmd no está instalado"
    fi
}

# Preguntar confirmación al usuario
# Uso: confirm "¿Continuar?" && hacer_algo
confirm() {
    local prompt="${1:-¿Continuar?}"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi
    
    echo -ne "${YELLOW}$prompt ${NC}"
    read -r response
    
    response=${response:-$default}
    case "$response" in
        [yY][eE][sS]|[yY]|[sS][iI])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Ejecutar comando con manejo de errores
# Uso: safe_run "comando" "CÓDIGO_ERROR" "descripción del error"
safe_run() {
    local cmd="$1"
    local error_code="${2:-COMMAND_FAILED}"
    local error_desc="${3:-El comando falló: $cmd}"
    
    debug "Ejecutando: $cmd"
    
    if ! eval "$cmd"; then
        handle_error "$error_code" "$error_desc"
        return 1
    fi
    
    return 0
}

# Configurar trap para limpieza en caso de error
setup_error_trap() {
    trap 'error_trap_handler $? $LINENO' ERR
}

error_trap_handler() {
    local exit_code=$1
    local line_number=$2
    
    if [ $exit_code -ne 0 ]; then
        echo ""
        error "El script falló en la línea $line_number con código de salida $exit_code"
        echo -e "${GRAY}Consulta el log: $ERROR_LOG_FILE${NC}"
        echo ""
    fi
}

# ==========================================
# INICIALIZACIÓN
# ==========================================

# Mensaje de que la librería fue cargada (solo en modo debug)
debug "Librería common.sh cargada correctamente"

# Exportar funciones para que estén disponibles en scripts que importen esta librería
export -f log success info warning error debug progress
export -f handle_error get_error_solution
export -f check_command check_commands check_directory check_file
export -f show_header show_version confirm safe_run
export -f setup_error_trap error_trap_handler
