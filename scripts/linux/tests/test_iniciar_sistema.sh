#!/bin/bash
# Tests para scripts de iniciar_sistema

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test: Verificar scripts de iniciar_sistema
test_sistema_scripts_exist() {
    local scripts=(
        "inject_aliases.sh"
        "setup_git_gitea.sh"
    )
    
    for script in "${scripts[@]}"; do
        local path="$SCRIPT_DIR/iniciar_sistema/$script"
        [ -f "$path" ] || return 1
        [ -x "$path" ] || return 1
        
        # Verificar sintaxis bash
        bash -n "$path" || return 1
    done
    
    return 0
}

# Ejecutar tests
test_sistema_scripts_exist || exit 1

exit 0
