#!/bin/bash
# Tests para scripts de inicializar_repos

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test: Verificar que todos los scripts de inicializar_repos existen
test_init_scripts_exist() {
    local scripts=(
        "init_frontend_project.sh"
        "init_go_module.sh"
        "init_python_project.sh"
        "init_wails_project.sh"
    )
    
    for script in "${scripts[@]}"; do
        local path="$SCRIPT_DIR/inicializar_repos/$script"
        [ -f "$path" ] || return 1
        [ -x "$path" ] || return 1
        
        # Verificar sintaxis bash
        bash -n "$path" || return 1
    done
    
    return 0
}

# Test: Verificar que los scripts tienen las funciones esperadas
test_init_scripts_structure() {
    local script="$SCRIPT_DIR/inicializar_repos/init_frontend_project.sh"
    
    # Verificar que contiene descripción (Script: o Script para)
    grep -qE "# Script[: ]" "$script" || return 1
    
    return 0
}

# Ejecutar tests
test_init_scripts_exist || exit 1
test_init_scripts_structure || exit 1

exit 0
