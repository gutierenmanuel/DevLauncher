#!/usr/bin/env bash
set -euo pipefail

# Script para configurar Git con credenciales de Gitea
# Configura usuario, email, y guarda token de forma segura

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# ==== CONFIGURACIÓN INICIAL ===============================================
# Puedes editar estos valores o pasarlos como argumentos
GIT_USER="${1:-egutierrez}"
GIT_EMAIL="${2:-egutierrez@dead.dd}"
GITEA_HOST="${3:-10.8.0.6:3123}"  # dominio o IP de tu Gitea (sin https://)
# =========================================================================

show_header "Configuración de Git + Gitea 🔧" "Setup de credenciales seguro"

info "Configuración que se aplicará:"
echo -e "  ${CYAN}Usuario:${NC} $GIT_USER"
echo -e "  ${CYAN}Email:${NC}   $GIT_EMAIL"
echo -e "  ${CYAN}Host:${NC}    $GITEA_HOST"
echo ""

if ! confirm "¿Deseas continuar?" "y"; then
    info "Configuración cancelada"
    exit 0
fi
echo ""

# 0. Pedir token al usuario
echo -e "${YELLOW}Por favor, introduce tu token de Gitea:${NC}"
read -rsp "Token: " GITEA_TOKEN
echo ""
echo ""

if [[ -z "$GITEA_TOKEN" ]]; then
    handle_error "TOKEN_EMPTY" "El token no puede estar vacío" \
        "Genera un token en Gitea: Settings → Applications → Generate Token"
    exit 1
fi

# 1. Configuración global de Git
progress "Configurando usuario y correo de Git..."
git config --global user.name  "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
success "Git configurado con user.name='$GIT_USER', user.email='$GIT_EMAIL'"
echo ""

# 2. Guardar credenciales con helper seguro
progress "Configurando helper de credenciales..."
git config --global credential.helper store
success "credential.helper configurado"
echo ""

# 3. Generar entrada en ~/.git-credentials para el host de Gitea
CRED_FILE="$HOME/.git-credentials"
URL="https://${GIT_USER}:${GITEA_TOKEN}@${GITEA_HOST}"

progress "Guardando credenciales en $CRED_FILE..."

if [[ -f "$CRED_FILE" ]] && grep -q "${GITEA_HOST}" "$CRED_FILE" 2>/dev/null; then
    warning "Ya existe una entrada para ${GITEA_HOST} en $CRED_FILE"
    echo ""
    
    if confirm "¿Deseas reemplazarla?" "y"; then
        # Eliminar línea vieja
        grep -v "${GITEA_HOST}" "$CRED_FILE" > "${CRED_FILE}.tmp" || true
        mv "${CRED_FILE}.tmp" "$CRED_FILE"
        echo "$URL" >> "$CRED_FILE"
        chmod 600 "$CRED_FILE"
        success "Token de Gitea actualizado en $CRED_FILE"
    else
        info "Token no actualizado, usando el existente"
    fi
else
    echo "$URL" >> "$CRED_FILE"
    chmod 600 "$CRED_FILE"
    success "Token de Gitea añadido a $CRED_FILE"
fi
echo ""

# 4. Configurar .gitconfig para usar ese host con https
progress "Configurando URL rewrite para Gitea..."
git config --global url."https://${GIT_USER}@${GITEA_HOST}/".insteadOf "https://${GITEA_HOST}/"
success "URL rewrite configurado"
echo ""

# 5. Configuraciones adicionales recomendadas
progress "Aplicando configuraciones adicionales..."

# Editor por defecto
if command -v nano &>/dev/null; then
    git config --global core.editor "nano"
elif command -v vim &>/dev/null; then
    git config --global core.editor "vim"
fi

# Colores en Git
git config --global color.ui auto

# Push simple (solo la rama actual)
git config --global push.default simple

# Pull con rebase por defecto
git config --global pull.rebase false

# Autocorrección de comandos
git config --global help.autocorrect 1

success "Configuraciones adicionales aplicadas"
echo ""

# =========================
#  RESUMEN Y VERIFICACIÓN
# =========================

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ Git y Gitea configurados correctamente"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📋 Resumen de configuración:"
echo -e "  ${GREEN}✓${NC} Usuario Git:    $GIT_USER"
echo -e "  ${GREEN}✓${NC} Email Git:      $GIT_EMAIL"
echo -e "  ${GREEN}✓${NC} Host Gitea:     $GITEA_HOST"
echo -e "  ${GREEN}✓${NC} Credenciales:   guardadas en $CRED_FILE"
echo -e "  ${GREEN}✓${NC} URL rewrite:    configurado"
echo ""

info "🔑 Tu token está guardado de forma segura en:"
echo -e "   ${CYAN}$CRED_FILE${NC} (permisos: 600)"
echo ""

info "📚 Ahora puedes clonar repos con:"
echo -e "   ${YELLOW}git clone https://${GITEA_HOST}/NOMBRE_ORG/REPO.git${NC}"
echo ""

info "🧪 Verifica la configuración con:"
echo -e "   ${YELLOW}git config --global --list${NC}"
echo ""

# Verificación opcional
if confirm "¿Deseas ver la configuración global de Git?" "n"; then
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    git config --global --list | grep -E "(user\.|credential\.|url\.)" || git config --global --list
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
fi

success "🎉 ¡Configuración completada!"
