#!/bin/bash

# Script de monitoreo de puertos y conexiones de red
# Muestra puertos abiertos, procesos y conexiones establecidas

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
    show_header "Puertos Activos 🔌" "Monitoreo de red y conexiones"
    
    echo -e "${CYAN}Opciones disponibles:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Ver todos los puertos abiertos (Listening)"
    echo -e "  ${GREEN}2.${NC} Ver puertos TCP"
    echo -e "  ${GREEN}3.${NC} Ver puertos UDP"
    echo -e "  ${GREEN}4.${NC} Buscar proceso por puerto específico"
    echo -e "  ${GREEN}5.${NC} Ver conexiones establecidas"
    echo -e "  ${GREEN}6.${NC} Ver puertos por proceso"
    echo -e "  ${GREEN}7.${NC} Ver estadísticas de red"
    echo -e "  ${GREEN}8.${NC} Escanear puerto específico"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
}

show_all_ports() {
    progress "Mostrando todos los puertos abiertos (LISTEN)..."
    echo ""
    
    if command -v ss &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Puertos en escucha:${NC}"
        echo ""
        ss -tulnp 2>/dev/null | awk 'NR==1 || /LISTEN/ {print}' | column -t
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    elif command -v netstat &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Puertos en escucha:${NC}"
        echo ""
        netstat -tulnp 2>/dev/null | awk 'NR<=2 || /LISTEN/ {print}' | column -t
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

show_tcp_ports() {
    progress "Mostrando puertos TCP..."
    echo ""
    
    if command -v ss &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Puertos TCP:${NC}"
        echo ""
        ss -tnlp 2>/dev/null | column -t
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    elif command -v netstat &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Puertos TCP:${NC}"
        echo ""
        netstat -tnlp 2>/dev/null | column -t
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

show_udp_ports() {
    progress "Mostrando puertos UDP..."
    echo ""
    
    if command -v ss &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Puertos UDP:${NC}"
        echo ""
        ss -unlp 2>/dev/null | column -t
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    elif command -v netstat &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Puertos UDP:${NC}"
        echo ""
        netstat -unlp 2>/dev/null | column -t
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

search_port() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el número de puerto: ${NC})" port
    
    if [[ -z "$port" ]]; then
        warning "Puerto vacío"
        return 1
    fi
    
    echo ""
    progress "Buscando información del puerto $port..."
    echo ""
    
    if command -v ss &>/dev/null; then
        local tcp_results=$(ss -tlnp 2>/dev/null | grep ":$port " || true)
        local udp_results=$(ss -ulnp 2>/dev/null | grep ":$port " || true)
        
        if [[ -n "$tcp_results" ]]; then
            echo -e "${GREEN}Puerto $port (TCP):${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$tcp_results"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo ""
        fi
        
        if [[ -n "$udp_results" ]]; then
            echo -e "${GREEN}Puerto $port (UDP):${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$udp_results"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo ""
        fi
        
        if [[ -z "$tcp_results" && -z "$udp_results" ]]; then
            warning "El puerto $port no está en uso"
        fi
    elif command -v netstat &>/dev/null; then
        local results=$(netstat -tulnp 2>/dev/null | grep ":$port " || true)
        
        if [[ -z "$results" ]]; then
            warning "El puerto $port no está en uso"
        else
            echo -e "${GREEN}Puerto $port:${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$results"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        fi
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

show_established() {
    progress "Mostrando conexiones establecidas..."
    echo ""
    
    if command -v ss &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Conexiones TCP establecidas:${NC}"
        echo ""
        ss -tnp 2>/dev/null | awk 'NR==1 || /ESTAB/ {print}' | column -t | head -30
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        
        local count=$(ss -tnp 2>/dev/null | grep -c ESTAB || echo 0)
        echo ""
        info "Total de conexiones establecidas: $count"
    elif command -v netstat &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Conexiones TCP establecidas:${NC}"
        echo ""
        netstat -tnp 2>/dev/null | awk 'NR<=2 || /ESTABLISHED/ {print}' | column -t | head -30
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        
        local count=$(netstat -tnp 2>/dev/null | grep -c ESTABLISHED || echo 0)
        echo ""
        info "Total de conexiones establecidas: $count"
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

ports_by_process() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el nombre del proceso: ${NC})" process_name
    
    if [[ -z "$process_name" ]]; then
        warning "Nombre vacío"
        return 1
    fi
    
    echo ""
    progress "Buscando puertos usados por '$process_name'..."
    echo ""
    
    if command -v ss &>/dev/null; then
        local results=$(ss -tulnp 2>/dev/null | grep -i "$process_name" || true)
        
        if [[ -z "$results" ]]; then
            warning "No se encontraron puertos usados por '$process_name'"
        else
            echo -e "${GREEN}Puertos usados por $process_name:${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$results" | column -t
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        fi
    elif command -v netstat &>/dev/null; then
        local results=$(netstat -tulnp 2>/dev/null | grep -i "$process_name" || true)
        
        if [[ -z "$results" ]]; then
            warning "No se encontraron puertos usados por '$process_name'"
        else
            echo -e "${GREEN}Puertos usados por $process_name:${NC}"
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
            echo "$results" | column -t
            echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        fi
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

network_stats() {
    progress "Mostrando estadísticas de red..."
    echo ""
    
    if command -v ss &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Resumen de conexiones:${NC}"
        echo ""
        ss -s
        echo ""
        echo -e "${BOLD}Interfaces de red:${NC}"
        echo ""
        ip -br addr 2>/dev/null || ifconfig -a 2>/dev/null || echo "No se pudo obtener info de interfaces"
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    elif command -v netstat &>/dev/null; then
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}Estadísticas de red:${NC}"
        echo ""
        netstat -s | head -50
        echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    else
        error "No se encontró ss o netstat en el sistema"
        return 1
    fi
    echo ""
}

scan_port() {
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el puerto a escanear: ${NC})" port
    
    if [[ -z "$port" ]]; then
        warning "Puerto vacío"
        return 1
    fi
    
    read -p "$(echo -e ${CYAN}Introduce el host \(Enter para localhost\): ${NC})" host
    host="${host:-localhost}"
    
    echo ""
    progress "Escaneando puerto $port en $host..."
    echo ""
    
    if command -v nc &>/dev/null; then
        if timeout 2 nc -zv "$host" "$port" 2>&1 | grep -q "succeeded\|open"; then
            success "Puerto $port está ABIERTO en $host"
        else
            warning "Puerto $port está CERRADO en $host"
        fi
    elif command -v telnet &>/dev/null; then
        if timeout 2 telnet "$host" "$port" 2>&1 | grep -q "Connected"; then
            success "Puerto $port está ABIERTO en $host"
        else
            warning "Puerto $port está CERRADO en $host"
        fi
    else
        # Usar bash built-in
        if timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            success "Puerto $port está ABIERTO en $host"
        else
            warning "Puerto $port está CERRADO o no responde en $host"
        fi
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
                show_all_ports
                ;;
            2)
                show_tcp_ports
                ;;
            3)
                show_udp_ports
                ;;
            4)
                search_port
                ;;
            5)
                show_established
                ;;
            6)
                ports_by_process
                ;;
            7)
                network_stats
                ;;
            8)
                scan_port
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
