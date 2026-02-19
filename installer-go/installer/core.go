package installer

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

// GetInstallDir returns the default installation directory.
func GetInstallDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("USERPROFILE")
		if home == "" {
			home = os.Getenv("HOME")
		}
	}
	if runtime.GOOS == "windows" {
		return filepath.Join(home, ".devscripts")
	}
	return filepath.Join(home, ".devscripts")
}

// ParseVersion extracts the version tag (e.g. "v1.4.0") from the first word of the first line.
func ParseVersion(content string) string {
	line := strings.SplitN(strings.TrimSpace(content), "\n", 2)[0]
	word := strings.Fields(line)
	if len(word) == 0 {
		return ""
	}
	return word[0]
}

// CompareVersions compares semver strings like "v1.4.0". Returns -1, 0, or 1.
func CompareVersions(a, b string) int {
	pa := parseParts(a)
	pb := parseParts(b)
	for i := 0; i < 3; i++ {
		if pa[i] < pb[i] {
			return -1
		}
		if pa[i] > pb[i] {
			return 1
		}
	}
	return 0
}

func parseParts(v string) [3]int {
	v = strings.TrimPrefix(v, "v")
	parts := strings.SplitN(v, ".", 3)
	var nums [3]int
	for i, p := range parts {
		if i >= 3 {
			break
		}
		n, _ := strconv.Atoi(p)
		nums[i] = n
	}
	return nums
}

// ExistingInstall represents a previously installed DevScripts installation.
type ExistingInstall struct {
	Dir     string
	Version string
}

// DetectExistingInstall checks if an installation already exists at installDir.
func DetectExistingInstall(installDir string) (*ExistingInstall, error) {
	versionFile := filepath.Join(installDir, "VERSION.txt")
	data, err := os.ReadFile(versionFile)
	if os.IsNotExist(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &ExistingInstall{
		Dir:     installDir,
		Version: ParseVersion(string(data)),
	}, nil
}

// CountAssets counts files in the assets/ embed (excluding .gitkeep).
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

// ExtractAssets extracts all embedded assets to destDir.
// progress callback is called for each file extracted.
func ExtractAssets(fsys embed.FS, destDir string, progress func(current, total int, filename string)) error {
	total := CountAssets(fsys)
	current := 0

	return fs.WalkDir(fsys, "assets", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		base := filepath.Base(path)
		if base == ".gitkeep" || base == "placeholder" {
			return nil
		}

		destPath := mapAssetPath(path, destDir)
		if destPath == "" {
			return nil
		}

		if err := os.MkdirAll(filepath.Dir(destPath), 0755); err != nil {
			return err
		}

		data, err := fsys.ReadFile(path)
		if err != nil {
			return err
		}

		perm := fs.FileMode(0644)
		if isExecutable(path) {
			perm = 0755
		}
		if err := os.WriteFile(destPath, data, perm); err != nil {
			return err
		}

		current++
		if progress != nil {
			progress(current, total, filepath.Base(destPath))
		}
		return nil
	})
}

// mapAssetPath converts an embedded path to the destination path.
func mapAssetPath(embPath, destDir string) string {
	// assets/scripts/... → {destDir}/scripts/...
	// assets/static/...  → {destDir}/static/...
	// assets/VERSION.txt → {destDir}/VERSION.txt
	// assets/launcher.exe → {destDir}/launcher.exe  (windows)
	// assets/launcher-linux → {destDir}/launcher    (linux)
	// assets/launcher-mac → {destDir}/launcher      (darwin)
	// assets/uninstaller.exe → {destDir}/uninstaller.exe (windows)
	// assets/uninstaller-linux → {destDir}/uninstaller   (linux)
	rel := strings.TrimPrefix(embPath, "assets/")

	switch {
	case strings.HasPrefix(rel, "scripts/") || strings.HasPrefix(rel, "static/") || rel == "VERSION.txt":
		return filepath.Join(destDir, filepath.FromSlash(rel))
	case rel == "launcher.exe":
		if runtime.GOOS == "windows" {
			return filepath.Join(destDir, "launcher.exe")
		}
		return "" // skip on unix
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

func isExecutable(path string) bool {
	base := filepath.Base(path)
	return base == "launcher.exe" || base == "launcher-linux" || base == "launcher-mac" || base == "uninstaller.exe" || base == "uninstaller-linux"
}

// GetLauncherPath returns the launcher executable path inside installDir for current OS.
func GetLauncherPath(installDir string) string {
	if runtime.GOOS == "windows" {
		return filepath.Join(installDir, "launcher.exe")
	}
	return filepath.Join(installDir, "launcher")
}

// RemoveInstallDir deletes the entire installation directory.
func RemoveInstallDir(installDir string) error {
	return os.RemoveAll(installDir)
}
