package middleware

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/lucas/installer/core"
)

// ExtractAssets extracts all embedded assets to destDir.
// progress callback is called for each file extracted.
func ExtractAssets(fsys embed.FS, destDir string, progress func(current, total int, filename string)) error {
	total := core.CountAssets(fsys)
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

		destPath := core.MapAssetPath(path, destDir)
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
		if core.IsExecutable(path) {
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
