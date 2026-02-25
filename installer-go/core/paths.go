package core

import (
	"os"
	"path/filepath"
	"runtime"
)

// GetInstallDir returns the default installation directory for DevLauncher.
func GetInstallDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("USERPROFILE")
		if home == "" {
			home = os.Getenv("HOME")
		}
	}
	return filepath.Join(home, ".devlauncher")
}

// GetLauncherPath returns the launcher executable path inside installDir for the current OS.
func GetLauncherPath(installDir string) string {
	if runtime.GOOS == "windows" {
		return filepath.Join(installDir, "launcher.exe")
	}
	return filepath.Join(installDir, "launcher")
}
