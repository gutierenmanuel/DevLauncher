package middleware

import (
	"path/filepath"
	"runtime"
)

// platform represents the detected operating system subfolder name.
type platform string

const (
	platformLinux   platform = "linux"
	platformWindows platform = "win"
)

// detectPlatform returns the scripts subfolder for the current OS.
func detectPlatform() platform {
	switch runtime.GOOS {
	case "windows":
		return platformWindows
	default:
		return platformLinux // macOS uses linux scripts
	}
}

// GetScriptsPath returns the absolute path to the platform-specific scripts directory.
func GetScriptsPath(rootDir string) string {
	return filepath.Join(rootDir, "scripts", string(detectPlatform()))
}

// GetStaticPath returns the absolute path to the static assets directory.
func GetStaticPath(rootDir string) string {
	return filepath.Join(rootDir, "static")
}
