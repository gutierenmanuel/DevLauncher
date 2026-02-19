#!/bin/bash
# Tests para scripts de instaladores

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test: Verificar que todos los scripts de instaladores existen
test_installer_scripts_exist() {
    local scripts=(
        "instalar_go.sh"
        "instalar_nodejs.sh"
        "instalar_pnpm.sh"
        "instalar_python312.sh"
        "instalar_uv.sh"
        "instalar_volta.sh"
        "instalar_wails.sh"
    )
    
    for script in "${scripts[@]}"; do
        local path="$SCRIPT_DIR/instaladores/$script"
        [ -f "$path" ] || return 1
        [ -x "$path" ] || return 1
        
        # Verificar sintaxis bash
        bash -n "$path" || return 1
    done
    
    return 0
}

# Test: Verificar que los instaladores tienen descripción
test_installers_have_description() {
    for script in "$SCRIPT_DIR/instaladores"/*.sh; do
        [ -f "$script" ] || continue
        grep -qE "# Script[: ]" "$script" || return 1
    done
    
    return 0
}

# Ejecutar tests
test_installer_scripts_exist || exit 1
test_installers_have_description || exit 1

exit 0
