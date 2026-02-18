#!/usr/bin/env bash
set -euo pipefail

# Script para inyectar aliases y funciones en bashrc/zshrc
# Detecta cambios mediante hash SHA256 y actualiza automáticamente

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

# =========================
#  Variables
# =========================

# Permite override manual: TARGET=~/.zshrc ./inject_aliases.sh
TARGET="${TARGET:-}"
BASE_DIR="${1:-$SCRIPT_DIR}"
PARENT_DIR="$(cd "$BASE_DIR/.." && pwd -P)"

# =========================
#  Funciones auxiliares
# =========================

detect_target() {
  if [[ -n "${TARGET:-}" ]]; then
    printf "%s" "$TARGET"
    return
  fi
  # Detecta shell actual; por defecto usa ~/.bashrc
  local shell_name="${SHELL##*/}"
  case "$shell_name" in
    zsh)  printf "%s" "${HOME}/.zshrc" ;;
    bash) printf "%s" "${HOME}/.bashrc" ;;
    *)    printf "%s" "${HOME}/.bashrc" ;;
  esac
}

ensure_file() {
  local f="$1"
  [[ -f "$f" ]] || { : > "$f"; success "Creado $f"; }
}

hash256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

ensure_trailing_newline() {
  local f="$1"
  # Añade un salto de línea sólo si el archivo no termina en \n
  if [[ -s "$f" ]]; then
    if [[ "$(tail -c1 "$f" | wc -l)" -eq 0 ]]; then
      echo >> "$f"
    fi
  fi
}

# Inyección de bloques
add_chunk() {
  local content hash first_line
  content="$(cat)"
  [[ -z "$content" ]] && { warning "Bloque vacío; omitido."; return 0; }

  hash="$(printf "%s" "$content" | hash256)"
  first_line="$(printf "%s" "$content" | head -n1)"

  # 1. Caso: ya existe el mismo bloque con el mismo hash → no hacer nada
  if grep -Fq "# SNIPPET ${first_line} sha256:${hash}" "$RC_TARGET"; then
    info "Snippet '${first_line}' ya presente (sha256=${hash:0:8}) → omitido."
    return 0
  fi

  # 2. Caso: existe un bloque con la misma primera línea pero hash distinto → reemplazar
  if grep -Fq "# SNIPPET ${first_line}" "$RC_TARGET"; then
    warning "Encontrado snippet viejo '${first_line}' con hash distinto → reemplazando..."
    # borrar bloque viejo desde la cabecera SNIPPET hasta antes del próximo SNIPPET o EOF
    sed -i.bak "/# SNIPPET ${first_line}/,/^# SNIPPET /{//!d}; /^# SNIPPET ${first_line}/d" "$RC_TARGET"
  fi

  # 3. Agregar bloque nuevo
  {
    printf "\n# SNIPPET %s sha256:%s\n" "$first_line" "$hash"
    printf "%s\n" "$content"
  } >> "$RC_TARGET"

  success "Snippet actualizado '${first_line}' (sha256=${hash:0:8})"
}

# =========================
#  Main
# =========================

main() {
  show_header "Inyector de Aliases 💉" "Configuración de shell automática"
  
  RC_TARGET="$(detect_target)"
  BACKUP="${RC_TARGET}.bak.$(date +%Y%m%d-%H%M%S)"

  info "Objetivo: $RC_TARGET"
  ensure_file "$RC_TARGET"

  progress "Creando backup..."
  cp -f -- "$RC_TARGET" "$BACKUP" 2>/dev/null || cp -f "$RC_TARGET" "$BACKUP"
  success "Backup creado: $BACKUP"
  echo ""

  # =========================
  #  Bloques de Alias y Funciones
  #  Añade aquí todos los snippets que quieras inyectar
  # =========================

  progress "Inyectando funciones de Python..."
  add_chunk <<'BASH'
# Función para activar entorno virtual Python
vnv() {
  if [[ -d ".venv" ]]; then
    source .venv/bin/activate
    echo "✓ Entorno virtual activado (.venv)"
  else
    echo "✗ No se encontró .venv en el directorio actual"
    return 1
  fi
}
BASH

  add_chunk <<'BASH'
# Crear entorno virtual con uv
mkvenv() {
  local name="${1:-.venv}"
  if command -v uv &>/dev/null; then
    uv venv "$name"
    echo "✓ Entorno virtual creado con uv: $name"
  else
    python3 -m venv "$name"
    echo "✓ Entorno virtual creado: $name"
  fi
}
BASH

  progress "Inyectando funciones de Git..."
  add_chunk <<'BASH'
# Función para commit rápido
gcm() {
  local msg="$*"
  if [[ -z "$msg" ]]; then
    echo "Uso: gcm <mensaje del commit>"
    return 1
  fi
  git add . && git commit -m "$msg"
}
BASH

  add_chunk <<'BASH'
# Función para push rápido
gp() {
  local branch="${1:-$(git branch --show-current)}"
  git push origin "$branch"
}
BASH

  add_chunk <<'BASH'
# Status de git con formato limpio
gs() {
  git status -sb
}
BASH

  progress "Inyectando funciones de desarrollo..."
  add_chunk <<'BASH'
# Navegación rápida a proyectos
cdp() {
  local project="${1:-}"
  if [[ -z "$project" ]]; then
    cd ~/proyectos || cd ~/Proyectos || cd ~/projects || cd ~/Projects
  else
    cd ~/proyectos/"$project" || cd ~/Proyectos/"$project" || cd ~/projects/"$project" || cd ~/Projects/"$project"
  fi
}
BASH

  add_chunk <<'BASH'
# Limpiar cache de Python
pyclean() {
  find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
  find . -type f -name "*.pyc" -delete 2>/dev/null
  find . -type f -name "*.pyo" -delete 2>/dev/null
  find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null
  echo "✓ Cache de Python limpiado"
}
BASH

  add_chunk <<'BASH'
# Limpiar node_modules
nmclean() {
  find . -type d -name "node_modules" -prune -exec rm -rf {} + 2>/dev/null
  echo "✓ node_modules eliminados"
}
BASH

  progress "Inyectando aliases útiles..."
  add_chunk <<'BASH'
# Alias de navegación
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
BASH

  add_chunk <<'BASH'
# Alias de listado mejorado
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
BASH

  add_chunk <<'BASH'
# Alias de Git
alias ga='git add'
alias gaa='git add .'
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gdc='git diff --cached'
alias gb='git branch'
alias gba='git branch -a'
BASH

  add_chunk <<'BASH'
# Alias de Docker (si está instalado)
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
BASH

  add_chunk <<'BASH'
# Alias de desarrollo
alias py='python3'
alias pip='python3 -m pip'
alias serve='python3 -m http.server'
BASH

  # ----------------------------------------------------------------
  # Puedes añadir más bloques aquí
  # add_chunk <<'BASH'
  # my_custom_function() {
  #   echo "Mi función personalizada"
  # }
  # BASH
  # ----------------------------------------------------------------

  echo ""
  echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
  success "✅ Aliases y funciones inyectados correctamente"
  echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
  echo ""
  
  info "📝 Snippets inyectados:"
  echo -e "  ${GREEN}✓${NC} Funciones Python (vnv, mkvenv)"
  echo -e "  ${GREEN}✓${NC} Funciones Git (gcm, gp, gs)"
  echo -e "  ${GREEN}✓${NC} Funciones desarrollo (cdp, pyclean, nmclean)"
  echo -e "  ${GREEN}✓${NC} Aliases navegación (.., ..., ....)"
  echo -e "  ${GREEN}✓${NC} Aliases listado (ll, la, l)"
  echo -e "  ${GREEN}✓${NC} Aliases Git (ga, gst, gco, etc.)"
  echo -e "  ${GREEN}✓${NC} Aliases Docker (dps, di, dex, etc.)"
  echo -e "  ${GREEN}✓${NC} Aliases desarrollo (py, pip, serve)"
  echo ""
  
  info "🔄 Para aplicar los cambios ahora:"
  echo -e "   ${YELLOW}source \"$RC_TARGET\"${NC}"
  echo ""
  
  info "📦 Backup guardado en:"
  echo -e "   ${CYAN}$BACKUP${NC}"
  echo ""
}

main "$@"
