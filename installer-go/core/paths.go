package core

import (
	"path/filepath"
	"runtime"
)

// BuildInstallDir returns the default installation directory for DevLauncher
// from a provided home directory.
func BuildInstallDir(home string) string {
	return filepath.Join(home, ".devlauncher")
}

// GetLauncherPath returns the launcher executable path inside installDir for the current OS.
func GetLauncherPath(installDir string) string {
	if runtime.GOOS == "windows" {
		return filepath.Join(installDir, "launcher.exe")
	}
	return filepath.Join(installDir, "launcher")
}
