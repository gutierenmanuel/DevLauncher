package middleware

import (
	"os"

	"github.com/lucas/installer/core"
)

// DetectHomeDir resolves the current user home directory from OS/runtime env.
func DetectHomeDir() string {
	home, err := os.UserHomeDir()
	if err == nil && home != "" {
		return home
	}

	home = os.Getenv("USERPROFILE")
	if home != "" {
		return home
	}

	return os.Getenv("HOME")
}

// GetInstallDir returns the default install dir using OS-derived home.
func GetInstallDir() string {
	return core.BuildInstallDir(DetectHomeDir())
}
