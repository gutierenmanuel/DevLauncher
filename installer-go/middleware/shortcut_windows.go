//go:build windows

package middleware

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/lucas/installer/core"
)

// CreateDesktopShortcut creates a DevLauncher shortcut on the Windows Desktop.
// Returns the created shortcut path.
func CreateDesktopShortcut(installDir string) (string, error) {
	launcherPath := core.GetLauncherPath(installDir)
	iconPath := filepath.Join(installDir, "static", "devL.ico")

	quotePS := func(s string) string {
		return strings.ReplaceAll(s, "'", "''")
	}

	script := fmt.Sprintf(`
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'DevLauncher.lnk'
$target = '%s'
$workdir = '%s'
$icon = '%s'

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $target
$shortcut.WorkingDirectory = $workdir
if (Test-Path $icon) {
    $shortcut.IconLocation = $icon
}
$shortcut.Save()
Write-Output $shortcutPath
`, quotePS(launcherPath), quotePS(installDir), quotePS(iconPath))

	cmd := exec.Command("powershell", "-NoProfile", "-Command", script)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("creating desktop shortcut failed: %w (%s)", err, strings.TrimSpace(string(out)))
	}

	result := strings.TrimSpace(string(out))
	if result == "" {
		return "", fmt.Errorf("creating desktop shortcut failed: empty output")
	}
	return result, nil
}
