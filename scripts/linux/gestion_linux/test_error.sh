#!/bin/bash
# Script: Test de errores

echo "Iniciando script de prueba..."
echo "Este es un mensaje normal en stdout"
echo "ERROR: Este es un mensaje de error en stderr" >&2
echo "ERROR: Algo salió mal!" >&2
echo "Último mensaje antes de fallar..."
exit 1
