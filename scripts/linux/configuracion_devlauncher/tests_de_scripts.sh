#!/bin/bash
# Script: Ejecutar tests de scripts de Linux
# Lanza la suite de tests local de scripts Linux.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/tests/run_all_tests.sh"
