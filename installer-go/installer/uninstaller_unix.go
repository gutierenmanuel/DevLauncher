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

echo "Desinstalación en curso..."
(
  sleep 1
  rm -rf "$INSTALL_DIR"
) >/dev/null 2>&1 &

echo "DevLauncher desinstalado."
`

	path := filepath.Join(installDir, "uninstaller.sh")
	if err := os.WriteFile(path, []byte(content), 0755); err != nil {
		return err
	}
	return nil
}
