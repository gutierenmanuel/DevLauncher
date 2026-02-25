#!/usr/bin/env bash
# run.sh — Instala DevLauncher en Linux.
# Siempre compila desde fuente con build-all.sh y luego lanza el installer.

set -euo pipefail

# ─── Constantes ───────────────────────────────────────────────────────────────

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
VERSION_FILE="$ROOT_DIR/VERSION.txt"

# ─── Colores / UI ─────────────────────────────────────────────────────────────

_info()  { echo -e "\033[36m==> $*\033[0m"; }
_ok()    { echo -e "\033[32m✓  $*\033[0m"; }
_warn()  { echo -e "\033[33m⚠  $*\033[0m"; }
_error() { echo -e "\033[31m✗  $*\033[0m" >&2; }

# ─── Funciones puras ──────────────────────────────────────────────────────────

# Lee y devuelve la versión numérica desde VERSION.txt.
# Arg: $1 = ruta al VERSION.txt
# Salida: versión por stdout; exit 1 si no se puede leer
read_version() {
    local version_file="$1"

    if [[ ! -f "$version_file" ]]; then
        _error "No se encontró el archivo de versión: $version_file"
        return 1
    fi

    local token
    token="$(awk 'NR==1{print $1}' "$version_file")"
    local version="${token#v}"; version="${version#V}"

    if [[ -z "$version" ]]; then
        _error "No se pudo leer la versión desde: $version_file"
        return 1
    fi

    echo "$version"
}

# Construye la ruta esperada del installer Linux en dist/.
# Arg: $1 = directorio dist, $2 = versión
# Salida: ruta absoluta por stdout
resolve_installer_path() {
    local dist_dir="$1"
    local version="$2"
    echo "${dist_dir}/${version}-devlauncher-inst-linux"
}

# Comprueba si el binario existe y es ejecutable.
# Arg: $1 = ruta al binario
# Retorna: 0 si existe y es ejecutable, 1 en caso contrario
binary_ready() {
    local binary="$1"
    [[ -f "$binary" && -x "$binary" ]]
}

# Verifica que Go esté disponible en el PATH.
go_available() {
    command -v go &>/dev/null
}

# ─── Funciones de efecto (middleware) ─────────────────────────────────────────

# Compila todo el proyecto invocando build-all.sh.
# Arg: $1 = directorio raíz del proyecto
build_all() {
    local root_dir="$1"
    local build_script="${root_dir}/build-all.sh"

    if [[ ! -f "$build_script" ]]; then
        _error "No se encontró el script de build: $build_script"
        return 1
    fi

    if ! go_available; then
        _error "Go no está instalado o no está en el PATH"
        return 1
    fi

    _info "Compilando el proyecto completo (build-all.sh)..."
    bash "$build_script"
}

# Lanza el installer.
# Arg: $1 = ruta al binario del installer
launch_installer() {
    local binary="$1"
    _ok "Ejecutando installer: $(basename "$binary")"
    exec "$binary"
}

# ─── Orquestación (app) ───────────────────────────────────────────────────────

main() {
    local version
    version="$(read_version "$VERSION_FILE")"

    local installer
    installer="$(resolve_installer_path "$DIST_DIR" "$version")"

    build_all "$ROOT_DIR"

    if ! binary_ready "$installer"; then
        _error "La compilación terminó pero el installer no está disponible: $installer"
        exit 1
    fi

    _ok "Compilación completada"

    launch_installer "$installer"
}

main "$@"
