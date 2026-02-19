//go:build linux || darwin

package installer

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
)

// CreateDesktopShortcut creates a DevLauncher shortcut on the user's Desktop.
// Returns the created shortcut path.
func CreateDesktopShortcut(installDir string) (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	desktopDir := filepath.Join(home, "Desktop")
	if err := os.MkdirAll(desktopDir, 0755); err != nil {
		return "", err
	}

	launcherPath := GetLauncherPath(installDir)

	if runtime.GOOS == "darwin" {
		linkPath := filepath.Join(desktopDir, "DevLauncher")
		_ = os.Remove(linkPath)
		if err := os.Symlink(launcherPath, linkPath); err != nil {
			return "", err
		}
		return linkPath, nil
	}

	desktopFile := filepath.Join(desktopDir, "DevLauncher.desktop")
	iconPath := filepath.Join(installDir, "static", "devL.ico")
	content := fmt.Sprintf(`[Desktop Entry]
Type=Application
Name=DevLauncher
Comment=DevLauncher
Exec=%s
Icon=%s
Terminal=true
Categories=Development;
`, launcherPath, iconPath)

	if err := os.WriteFile(desktopFile, []byte(content), 0755); err != nil {
		return "", err
	}
	return desktopFile, nil
}
