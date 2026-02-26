package middleware

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
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

// ResolveRootDirWithLaunch resolves rootDir and launchDir using runtime paths.
// This function is intentionally impure and belongs to middleware.
func ResolveRootDirWithLaunch() (rootDir, launchDir string) {
	if cwd, err := os.Getwd(); err == nil {
		launchDir = cwd
	}

	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "..", "scripts")); err == nil {
			rootDir, _ = filepath.Abs("..")
		} else if _, err := os.Stat(filepath.Join(cwd, "scripts")); err == nil {
			rootDir = cwd
		}
	}

	if rootDir == "" {
		execPath, _ := os.Executable()
		realPath, _ := filepath.EvalSymlinks(execPath)
		rootDir = filepath.Dir(realPath)
	}

	if strings.TrimSpace(launchDir) == "" {
		launchDir = rootDir
	}
	return
}
