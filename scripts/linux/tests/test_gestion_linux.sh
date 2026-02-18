#!/bin/bash
# Tests para scripts de gestion_linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test 1: control_procesos.sh existe y tiene permisos
test_control_procesos() {
    local script="$SCRIPT_DIR/gestion_linux/control_procesos.sh"
    [ -f "$script" ] || return 1
    [ -x "$script" ] || return 1
    
    # Verificar sintaxis bash
    bash -n "$script" || return 1
    
    return 0
}

# Test 2: espacio_disponible.sh existe y tiene permisos
test_espacio_disponible() {
    local script="$SCRIPT_DIR/gestion_linux/espacio_disponible.sh"
    [ -f "$script" ] || return 1
    [ -x "$script" ] || return 1
    
    # Verificar sintaxis bash
    bash -n "$script" || return 1
    
    return 0
}

# Test 3: puertos_activos.sh existe y tiene permisos
test_puertos_activos() {
    local script="$SCRIPT_DIR/gestion_linux/puertos_activos.sh"
    [ -f "$script" ] || return 1
    [ -x "$script" ] || return 1
    
    # Verificar sintaxis bash
    bash -n "$script" || return 1
    
    return 0
}

# Ejecutar tests
test_control_procesos || exit 1
test_espacio_disponible || exit 1
test_puertos_activos || exit 1

exit 0
