package core

import (
	"embed"
	"io/fs"
	"path/filepath"
	"strings"
)

// CountAssets counts files in the assets/ embed (excluding .gitkeep and placeholder).
// Pure function: same input always produces same output.
func CountAssets(fsys embed.FS) int {
	count := 0
	_ = fs.WalkDir(fsys, "assets", func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return nil
		}
		base := filepath.Base(path)
		if base == ".gitkeep" || base == "placeholder" {
			return nil
		}
		count++
		return nil
	})
	return count
}

// MapAssetPath converts an embedded path to its destination path under destDir.
// Returns empty string if the path is not a recognized asset.
//
// Pure function: no side effects, no runtime.GOOS — each installer binary
// embeds only the files for its own platform (enforced by build tags in
// embed_linux.go / embed_windows.go / embed_darwin.go), so no OS-based
// filtering is needed here. Every file present in the embed IS the right one.
func MapAssetPath(embPath, destDir string) string {
	rel := strings.TrimPrefix(embPath, "assets/")

	switch {
	// Shared assets — copied preserving relative path
	case strings.HasPrefix(rel, "scripts/") || strings.HasPrefix(rel, "static/") || rel == "VERSION.txt":
		return filepath.Join(destDir, filepath.FromSlash(rel))

	// Launcher binaries — renamed to canonical "launcher" / "launcher.exe"
	case rel == "launcher.exe":
		return filepath.Join(destDir, "launcher.exe")
	case rel == "launcher-linux", rel == "launcher-mac":
		return filepath.Join(destDir, "launcher")

	// Uninstaller binaries — renamed to canonical "uninstaller" / "uninstaller.exe"
	case rel == "uninstaller.exe":
		return filepath.Join(destDir, "uninstaller.exe")
	case rel == "uninstaller-linux", rel == "uninstaller-mac":
		return filepath.Join(destDir, "uninstaller")
	}

	return ""
}

// IsExecutable returns true if the embedded file should be installed with execute permissions.
// Pure function: determined solely by filename, not by runtime state.
func IsExecutable(path string) bool {
	base := filepath.Base(path)
	return base == "launcher.exe" ||
		base == "launcher-linux" ||
		base == "launcher-mac" ||
		base == "uninstaller.exe" ||
		base == "uninstaller-linux" ||
		base == "uninstaller-mac"
}
