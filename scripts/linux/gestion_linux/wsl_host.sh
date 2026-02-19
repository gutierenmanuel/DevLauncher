#!/bin/bash

# Script de detección y acceso a Windows Host desde WSL
# Detecta si el sistema es WSL y permite abrir consolas de Windows

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# =========================
#  Funciones
# =========================

is_wsl() {
    # Método 1: Verificar /proc/version
    if [[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version; then
        return 0
    fi
    
    # Método 2: Verificar /proc/sys/kernel/osrelease
    if [[ -f /proc/sys/kernel/osrelease ]] && grep -qi "microsoft\|wsl" /proc/sys/kernel/osrelease; then
        return 0
    fi
    
    # Método 3: Verificar si existe /mnt/c y /proc/sys/fs/binfmt_misc/WSLInterop
    if [[ -d /mnt/c ]] && [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        return 0
    fi
    
    return 1
}

get_wsl_version() {
    if [[ -f /proc/version ]]; then
        if grep -qi "WSL2" /proc/version; then
            echo "WSL2"
        elif grep -qi "microsoft" /proc/version; then
            echo "WSL1"
        else
            echo "Unknown"
        fi
    else
        echo "Unknown"
    fi
}

get_windows_username() {
    # Obtener el usuario de Windows desde la variable de entorno
    if [[ -n "$WSLENV" ]]; then
        # Obtener desde cmd.exe
        cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

get_windows_version() {
    if command -v powershell.exe &>/dev/null; then
        powershell.exe -Command "[System.Environment]::OSVersion.Version.Major" 2>/dev/null | tr -d '\r\n' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

show_wsl_info() {
    clear
    show_header "Información WSL 🪟🐧" "Windows Subsystem for Linux"
    
    echo ""
    
    if ! is_wsl; then
        error "Este sistema NO es WSL"
        echo ""
        info "Este script solo funciona en entornos WSL (Windows Subsystem for Linux)"
        echo ""
        return 1
    fi
    
    local wsl_version=$(get_wsl_version)
    local win_user=$(get_windows_username)
    local win_version=$(get_windows_version)
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Información del entorno WSL:${NC}"
    echo ""
    echo -e "${CYAN}Versión de WSL:${NC}      $wsl_version"
    echo -e "${CYAN}Usuario Windows:${NC}     $win_user"
    echo -e "${CYAN}Windows Version:${NC}     $win_version"
    echo -e "${CYAN}Distribución:${NC}        $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${CYAN}Hostname:${NC}            $(hostname)"
    echo ""
    
    # Mostrar rutas de Windows montadas
    echo -e "${BOLD}Unidades de Windows montadas:${NC}"
    echo ""
    ls /mnt/ 2>/dev/null | grep -E "^[a-z]$" | while read drive; do
        echo -e "  ${GREEN}$drive:${NC} → /mnt/$drive"
    done
    echo ""
    
    # Ruta de Windows del directorio actual
    local current_win_path=$(wslpath -w "$(pwd)" 2>/dev/null || echo "N/A")
    echo -e "${CYAN}Directorio actual en Windows:${NC}"
    echo -e "  $current_win_path"
    echo ""
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

open_powershell() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    progress "Abriendo PowerShell en Windows Host..."
    echo ""
    
    if command -v powershell.exe &>/dev/null; then
        # Abrir PowerShell en el directorio actual (convertido a ruta Windows)
        local win_path=$(wslpath -w "$(pwd)" 2>/dev/null || echo "C:\\")
        success "PowerShell abierto correctamente"
        sleep 0.5
        # Usar exec para reemplazar el proceso actual con PowerShell
        exec powershell.exe -NoExit -Command "Set-Location '$win_path'"
    else
        error "No se pudo encontrar powershell.exe"
        return 1
    fi
}

open_cmd() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    progress "Abriendo CMD en Windows Host..."
    echo ""
    
    if command -v cmd.exe &>/dev/null; then
        # Abrir CMD en el directorio actual (convertido a ruta Windows)
        local win_path=$(wslpath -w "$(pwd)" 2>/dev/null || echo "C:\\")
        success "CMD abierto correctamente"
        sleep 0.5
        # Usar exec para reemplazar el proceso actual con CMD
        exec cmd.exe /k "cd /d $win_path"
    else
        error "No se pudo encontrar cmd.exe"
        return 1
    fi
}

open_windows_terminal() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    progress "Abriendo Windows Terminal..."
    echo ""
    
    if command -v wt.exe &>/dev/null; then
        # Abrir Windows Terminal en el directorio actual
        local win_path=$(wslpath -w "$(pwd)" 2>/dev/null || echo "C:\\")
        success "Windows Terminal abierto correctamente"
        sleep 0.5
        # Usar exec para reemplazar el proceso actual con Windows Terminal
        exec wt.exe -d "$win_path"
    else
        warning "Windows Terminal no encontrado"
        info "Instalalo desde Microsoft Store: https://aka.ms/terminal"
        echo ""
        info "Intentando abrir PowerShell como alternativa..."
        open_powershell
    fi
}

open_explorer() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    progress "Abriendo Explorador de Windows..."
    echo ""
    
    if command -v explorer.exe &>/dev/null; then
        # Abrir explorador en el directorio actual
        nohup explorer.exe . >/dev/null 2>&1 &
        disown
        success "Explorador de Windows abierto correctamente"
        sleep 1
    else
        error "No se pudo encontrar explorer.exe"
        return 1
    fi
    echo ""
}

open_notepad() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    read -p "$(echo -e ${CYAN}Introduce el nombre del archivo \(Enter para nuevo\): ${NC})" file_path
    
    progress "Abriendo Notepad..."
    echo ""
    
    if command -v notepad.exe &>/dev/null; then
        if [[ -n "$file_path" ]] && [[ -f "$file_path" ]]; then
            local win_path=$(wslpath -w "$file_path" 2>/dev/null)
            nohup notepad.exe "$win_path" >/dev/null 2>&1 &
        else
            nohup notepad.exe >/dev/null 2>&1 &
        fi
        disown
        success "Notepad abierto correctamente"
        sleep 1
    else
        error "No se pudo encontrar notepad.exe"
        return 1
    fi
    echo ""
}

open_vscode_windows() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    progress "Abriendo VS Code (Windows) en directorio actual..."
    echo ""
    
    if command -v code &>/dev/null; then
        nohup code . >/dev/null 2>&1 &
        disown
        success "VS Code abierto correctamente"
        sleep 1
    else
        warning "VS Code no encontrado o no está en PATH"
        info "Asegúrate de tener VS Code instalado en Windows con la extensión WSL"
    fi
    echo ""
}

run_custom_windows_command() {
    if ! is_wsl; then
        error "Este comando solo funciona en WSL"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Introduce el comando de Windows a ejecutar:${NC}"
    echo -e "${DIM}Ejemplos: ipconfig, systeminfo, tasklist${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Comando: ${NC})" win_command
    
    if [[ -z "$win_command" ]]; then
        warning "No se introdujo ningún comando"
        return 1
    fi
    
    echo ""
    progress "Ejecutando: $win_command"
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    
    cmd.exe /c "$win_command" 2>&1
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_menu() {
    clear
    show_header "Gestor WSL Host 🪟🐧" "Acceso a Windows desde WSL"
    
    # Verificar si es WSL
    if ! is_wsl; then
        echo ""
        error "⚠️  Este sistema NO es WSL"
        echo ""
        info "Este script solo funciona en Windows Subsystem for Linux"
        echo ""
        echo -e "${CYAN}¿Qué es WSL?${NC}"
        echo "WSL permite ejecutar Linux nativamente dentro de Windows 10/11"
        echo "Más info: https://aka.ms/wsl"
        echo ""
        read -p "$(echo -e ${CYAN}Presiona Enter para salir...${NC})"
        exit 1
    fi
    
    echo -e "${CYAN}Opciones disponibles:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Ver información de WSL"
    echo -e "  ${GREEN}2.${NC} Abrir PowerShell en Windows"
    echo -e "  ${GREEN}3.${NC} Abrir CMD en Windows"
    echo -e "  ${GREEN}4.${NC} Abrir Windows Terminal"
    echo -e "  ${GREEN}5.${NC} Abrir Explorador de Windows"
    echo -e "  ${GREEN}6.${NC} Abrir Notepad"
    echo -e "  ${GREEN}7.${NC} Abrir VS Code (Windows)"
    echo -e "  ${GREEN}8.${NC} Ejecutar comando personalizado de Windows"
    echo -e "  ${GREEN}0.${NC} Salir"
    echo ""
}

# =========================
#  Main Loop
# =========================

main() {
    # Si se pasa argumento --check, solo verificar y mostrar info
    if [[ "$1" == "--check" ]]; then
        show_wsl_info
        return 0
    fi
    
    # Si se pasa --powershell, abrir directamente PowerShell
    if [[ "$1" == "--powershell" ]] || [[ "$1" == "--ps" ]]; then
        if is_wsl; then
            open_powershell
        else
            error "Este sistema no es WSL"
            exit 1
        fi
        return 0
    fi
    
    # Si se pasa --cmd, abrir directamente CMD
    if [[ "$1" == "--cmd" ]]; then
        if is_wsl; then
            open_cmd
        else
            error "Este sistema no es WSL"
            exit 1
        fi
        return 0
    fi
    
    # Si se pasa --wt, abrir directamente Windows Terminal
    if [[ "$1" == "--wt" ]]; then
        if is_wsl; then
            open_windows_terminal
        else
            error "Este sistema no es WSL"
            exit 1
        fi
        return 0
    fi
    
    while true; do
        show_menu
        
        read -p "$(echo -e ${YELLOW}Selecciona una opción: ${NC})" option
        
        case $option in
            1)
                show_wsl_info
                read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
                ;;
            2)
                open_powershell
                # No llega aquí porque open_powershell hace exit
                ;;
            3)
                open_cmd
                # No llega aquí porque open_cmd hace exit
                ;;
            4)
                open_windows_terminal
                # No llega aquí porque open_windows_terminal hace exit
                ;;
            5)
                open_explorer
                read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
                ;;
            6)
                open_notepad
                read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
                ;;
            7)
                open_vscode_windows
                read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
                ;;
            8)
                run_custom_windows_command
                read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
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
                read -p "$(echo -e ${CYAN}Presiona Enter para continuar...${NC})"
                ;;
        esac
    done
}

main "$@"
