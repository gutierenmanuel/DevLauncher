#!/bin/bash
# Ejemplo de uso de la librería common.sh

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cargar la librería común
source "$SCRIPT_DIR/common.sh"

# Mostrar un header bonito
show_header "Ejemplo de uso de common.sh" "Demostrando funciones de la librería"

# Mostrar diferentes tipos de mensajes
success "Este es un mensaje de éxito"
info "Este es un mensaje informativo"
warning "Este es un mensaje de advertencia"
progress "Procesando algo..."

echo ""
info "Probando verificación de comandos..."

# Verificar comandos que existen
if check_command "ls" "LS_NOT_FOUND" "El comando ls no está disponible"; then
    success "El comando 'ls' está disponible"
fi

# Verificar un comando que NO existe (esto mostrará un error bonito)
echo ""
info "Ahora vamos a simular un error con un comando inexistente..."
if ! check_command "comando_inexistente_12345" "COMANDO_FALSO" "Este comando de prueba no existe"; then
    warning "Como se esperaba, el comando no existe"
fi

echo ""
success "Ejemplo completado! Revisa el log en: $ERROR_LOG_FILE"
