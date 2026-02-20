//go:build linux || darwin

package installer

import (
	"os"
	"path/filepath"
)

func GenerateUninstaller(installDir string) error {
	content := `#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_rc_file() {
  local shell_name="${SHELL:-}"
  if [[ "$shell_name" == *"zsh"* ]]; then echo "$HOME/.zshrc"; return; fi
  if [[ "$shell_name" == *"bash"* ]]; then echo "$HOME/.bashrc"; return; fi
  [[ -f "$HOME/.zshrc" ]] && { echo "$HOME/.zshrc"; return; }
  [[ -f "$HOME/.bashrc" ]] && { echo "$HOME/.bashrc"; return; }
  echo "$HOME/.bashrc"
}

remove_block() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '
    BEGIN { inblock=0 }
    /# DevScripts Installer/ { inblock=1; next }
    /# End DevScripts Installer/ { inblock=0; next }
    { if (!inblock) print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

RC_FILE="$(detect_rc_file)"
remove_block "$RC_FILE"

DESKTOP_DIR="$HOME/Desktop"
rm -f "$DESKTOP_DIR/DevLauncher.desktop" "$DESKTOP_DIR/DevLauncher" 2>/dev/null || true

echo "Desinstalación en curso..."

LEGACY_SCRIPTS_NAME=""
if [[ -d "$INSTALL_DIR/scripts" ]]; then
  SUFFIX="$(head /dev/urandom | tr -dc a-f0-9 | head -c 8)"
  LEGACY_SCRIPTS_NAME="scripts-old-${SUFFIX}"
  mv "$INSTALL_DIR/scripts" "$INSTALL_DIR/$LEGACY_SCRIPTS_NAME"
fi

for ITEM in "$INSTALL_DIR"/* "$INSTALL_DIR"/.[!.]* "$INSTALL_DIR"/..?*; do
  [[ -e "$ITEM" ]] || continue
  NAME="$(basename "$ITEM")"
  if [[ -n "$LEGACY_SCRIPTS_NAME" && "$NAME" == "$LEGACY_SCRIPTS_NAME" ]]; then
    continue
  fi
  rm -rf "$ITEM" 2>/dev/null || true
done

if [[ -n "$LEGACY_SCRIPTS_NAME" ]]; then
  echo "Scripts preservados en: $LEGACY_SCRIPTS_NAME"
else
  echo "No se encontró carpeta scripts para preservar."
fi

echo "DevLauncher desinstalado (excepto scripts preservados)."
`

	path := filepath.Join(installDir, "uninstaller.sh")
	if err := os.WriteFile(path, []byte(content), 0755); err != nil {
		return err
	}
	return nil
}
