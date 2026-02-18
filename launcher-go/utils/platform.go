package utils

import (
	"path/filepath"
	"runtime"
)

// Platform represents the detected operating system
type Platform string

const (
	PlatformLinux   Platform = "linux"
	PlatformWindows Platform = "win"
	PlatformDarwin  Platform = "linux" // macOS uses linux scripts
)

// DetectPlatform returns the current platform
func DetectPlatform() Platform {
	switch runtime.GOOS {
	case "windows":
		return PlatformWindows
	case "darwin":
		return PlatformDarwin
	default:
		return PlatformLinux
	}
}

// GetScriptsPath returns the path to scripts directory for the platform
func GetScriptsPath(rootDir string) string {
	platform := DetectPlatform()
	return filepath.Join(rootDir, "scripts", string(platform))
}

// GetStaticPath returns the path to static directory
func GetStaticPath(rootDir string) string {
	return filepath.Join(rootDir, "static")
}
