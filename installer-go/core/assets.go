package core

import (
"embed"
"io/fs"
"path/filepath"
"runtime"
"strings"
)

// CountAssets counts files in the assets/ embed (excluding .gitkeep and placeholder).
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

// MapAssetPath converts an embedded path to the destination path.
// Returns empty string if the file should be skipped on the current OS.
func MapAssetPath(embPath, destDir string) string {
rel := strings.TrimPrefix(embPath, "assets/")

switch {
case strings.HasPrefix(rel, "scripts/") || strings.HasPrefix(rel, "static/") || rel == "VERSION.txt":
return filepath.Join(destDir, filepath.FromSlash(rel))
case rel == "launcher.exe":
if runtime.GOOS == "windows" {
return filepath.Join(destDir, "launcher.exe")
}
return ""
case rel == "launcher-linux":
if runtime.GOOS == "linux" {
return filepath.Join(destDir, "launcher")
}
return ""
case rel == "launcher-mac":
if runtime.GOOS == "darwin" {
return filepath.Join(destDir, "launcher")
}
return ""
case rel == "uninstaller.exe":
if runtime.GOOS == "windows" {
return filepath.Join(destDir, "uninstaller.exe")
}
return ""
case rel == "uninstaller-linux":
if runtime.GOOS == "linux" {
return filepath.Join(destDir, "uninstaller")
}
return ""
}
return ""
}

// IsExecutable returns true if the embedded file should be installed as executable.
func IsExecutable(path string) bool {
base := filepath.Base(path)
return base == "launcher.exe" ||
base == "launcher-linux" ||
base == "launcher-mac" ||
base == "uninstaller.exe" ||
base == "uninstaller-linux"
}
