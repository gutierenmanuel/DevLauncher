#!/bin/bash

# Script de control y monitoreo de procesos
# Permite ver, buscar, filtrar y gestionar procesos del sistema

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# =========================
#  Funciones
# =========================

show_menu() {
    clear
    show_header "Control de Procesos 🔄" "Gestión y monitoreo del sistema"
    
    echo -e "${CYAN}Opciones disponibles:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Ver todos los procesos"
    echo -e "  ${GREEN}2.${NC} Buscar proceso por nombre"
    echo -e "  ${GREEN}3.${NC} Buscar proceso por puerto"
    echo -e "  ${GREEN}4.${NC} Ver procesos por usuario"
    echo -e "  ${GREEN}5.${NC} Top 10 procesos (CPU)"
    echo -e "  ${GREEN}6.${NC} Top 10 procesos (Memoria)"
    echo -e "  ${GREEN}7.${NC} Matar proceso"
    echo -e "  ${GREEN}8.${NC} Monitor en tiempo real (htop/top)"
    echo -e "  ${GREEN}9.${NC} Ver árbol de procesos"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
}

list_all_processes() {
    progress "Listando todos los procesos..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    ps aux --sort=-%cpu | head -30 | awk 'BEGIN {printf "%-10s %-6s %-5s %-5s %-10s %s\n", "USER", "PID", "%CPU", "%MEM", "TIME", "COMMAND"} NR>1 {printf "%-10s %-6s %-5s %-5s %-10s %s\n", $1, $2, $3, $4, $10, $11}'
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    
    echo ""
    info "Mostrando los primeros 30 procesos ordenados por CPU"
    echo ""
}

search_by_name() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el nombre del proceso: ${NC})" process_name
    
    if [[ -z "$process_name" ]]; then
        warning "Nombre vacío"
        return 1
    fi
    
    echo ""
    progress "Buscando procesos que coincidan con '$process_name'..."
    echo ""
    
    local results=$(ps aux | grep -i "$process_name" | grep -v grep)
    
    if [[ -z "$results" ]]; then
        warning "No se encontraron procesos con el nombre '$process_name'"
    else
        echo -e "${GREEN}Procesos encontrados:${NC}"
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo "$results" | awk 'BEGIN {printf "%-10s %-6s %-5s %-5s %s\n", "USER", "PID", "%CPU", "%MEM", "COMMAND"} {printf "%-10s %-6s %-5s %-5s %s\n", $1, $2, $3, $4, substr($0, index($0,$11))}'
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
}

search_by_port() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el número de puerto: ${NC})" port
    
    if [[ -z "$port" ]]; then
        warning "Puerto vacío"
        return 1
    fi
    
    echo ""
    progress "Buscando procesos usando el puerto $port..."
    echo ""
    
    if command -v ss &>/dev/null; then
        local results=$(ss -tlnp 2>/dev/null | grep ":$port " || true)
        
        if [[ -z "$results" ]]; then
            warning "No se encontraron procesos usando el puerto $port"
        else
            echo -e "${GREEN}Procesos usando el puerto $port:${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$results"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        fi
    elif command -v netstat &>/dev/null; then
        local results=$(netstat -tlnp 2>/dev/null | grep ":$port " || true)
        
        if [[ -z "$results" ]]; then
            warning "No se encontraron procesos usando el puerto $port"
        else
            echo -e "${GREEN}Procesos usando el puerto $port:${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$results"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        fi
    else
        error "No se encontró ss o netstat en el sistema"
    fi
    echo ""
}

processes_by_user() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el nombre de usuario \(Enter para actual\): ${NC})" username
    username="${username:-$(whoami)}"
    
    echo ""
    progress "Mostrando procesos del usuario '$username'..."
    echo ""
    
    local results=$(ps -u "$username" -o pid,ppid,cpu,pmem,time,cmd --sort=-%cpu 2>/dev/null || true)
    
    if [[ -z "$results" ]]; then
        warning "No se encontraron procesos del usuario '$username'"
    else
        echo -e "${GREEN}Procesos del usuario $username:${NC}"
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo "$results" | head -20
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
}

top_cpu() {
    progress "Top 10 procesos por uso de CPU..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    ps aux --sort=-%cpu | head -11 | awk 'BEGIN {printf "%-10s %-6s %-6s %-6s %s\n", "USER", "PID", "%CPU", "%MEM", "COMMAND"} NR>1 {printf "%-10s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, substr($0, index($0,$11))}'
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

top_memory() {
    progress "Top 10 procesos por uso de Memoria..."
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    ps aux --sort=-%mem | head -11 | awk 'BEGIN {printf "%-10s %-6s %-6s %-6s %s\n", "USER", "PID", "%CPU", "%MEM", "COMMAND"} NR>1 {printf "%-10s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, substr($0, index($0,$11))}'
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

kill_process() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el PID del proceso a terminar: ${NC})" pid
    
    if [[ -z "$pid" ]]; then
        warning "PID vacío"
        return 1
    fi
    
    # Verificar que el PID existe
    if ! ps -p "$pid" &>/dev/null; then
        error "No existe un proceso con PID $pid"
        return 1
    fi
    
    # Mostrar información del proceso
    echo ""
    info "Información del proceso:"
    ps -p "$pid" -o pid,ppid,user,%cpu,%mem,cmd
    echo ""
    
    if ! confirm "¿Estás seguro de que quieres terminar este proceso?" "n"; then
        info "Operación cancelada"
        return 0
    fi
    
    echo ""
    progress "Intentando terminar proceso $pid (SIGTERM)..."
    
    if kill "$pid" 2>/dev/null; then
        sleep 1
        
        if ps -p "$pid" &>/dev/null; then
            warning "El proceso aún está activo"
            echo ""
            
            if confirm "¿Quieres forzar la terminación (SIGKILL)?" "n"; then
                progress "Forzando terminación del proceso $pid..."
                if kill -9 "$pid" 2>/dev/null; then
                    success "Proceso $pid terminado forzadamente"
                else
                    error "No se pudo terminar el proceso (¿permisos insuficientes?)"
                fi
            fi
        else
            success "Proceso $pid terminado correctamente"
        fi
    else
        error "No se pudo terminar el proceso (¿permisos insuficientes?)"
    fi
    
    echo ""
}

monitor_realtime() {
    echo ""
    
    if command -v htop &>/dev/null; then
        info "Iniciando htop (presiona 'q' para salir)..."
        sleep 1
        htop
    elif command -v top &>/dev/null; then
        info "Iniciando top (presiona 'q' para salir)..."
        sleep 1
        top
    else
        error "No se encontró htop ni top en el sistema"
    fi
}

process_tree() {
    echo ""
    
    if command -v pstree &>/dev/null; then
        progress "Mostrando árbol de procesos..."
        echo ""
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        pstree -p | head -50
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo ""
        info "Mostrando primeros 50 procesos (usa 'pstree -p' para ver todos)"
    else
        warning "pstree no está instalado"
        info "Mostrando alternativa con ps..."
        echo ""
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        ps auxf | head -50
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
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
                list_all_processes
                ;;
            2)
                search_by_name
                ;;
            3)
                search_by_port
                ;;
            4)
                processes_by_user
                ;;
            5)
                top_cpu
                ;;
            6)
                top_memory
                ;;
            7)
                kill_process
                ;;
            8)
                monitor_realtime
                ;;
            9)
                process_tree
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
