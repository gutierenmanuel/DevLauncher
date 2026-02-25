package middleware

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/lucas/launcher/core"
)

// ScanCategories scans the platform scripts directory and returns all categories.
func ScanCategories(rootDir string) ([]core.Category, error) {
	scriptsPath := GetScriptsPath(rootDir)
	entries, err := os.ReadDir(scriptsPath)
	if err != nil {
		return nil, err
	}

	var categories []core.Category
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		if strings.EqualFold(entry.Name(), "lib") {
			continue
		}

		categoryPath := filepath.Join(scriptsPath, entry.Name())
		items, scanErr := ScanScripts(categoryPath)
		if scanErr != nil || len(items) == 0 {
			continue
		}

		dirCount, scriptCount := 0, 0
		for _, item := range items {
			if item.Extension == ".dir" {
				dirCount++
			} else {
				scriptCount++
			}
		}

		categories = append(categories, core.Category{
			Name:        entry.Name(),
			Path:        categoryPath,
			Icon:        folderIconFromREADME(categoryPath, entry.Name()),
			Description: folderDescriptionFromREADME(categoryPath, entry.Name()),
			DirCount:    dirCount,
			ScriptCount: scriptCount,
		})
	}

	return core.SortCategories(categories), nil
}

// ScanScripts scans a directory for executable scripts and subdirectories.
func ScanScripts(categoryPath string) ([]core.Script, error) {
	entries, err := os.ReadDir(categoryPath)
	if err != nil {
		return nil, err
	}

	plat := runtime.GOOS
	var scripts []core.Script

	for _, entry := range entries {
		entryPath := filepath.Join(categoryPath, entry.Name())

		if entry.IsDir() {
			if strings.EqualFold(entry.Name(), "lib") {
				continue
			}
			dirCount, scriptCount := countImmediateItems(entryPath, plat)
			scripts = append(scripts, core.Script{
				Name:        entry.Name(),
				Path:        entryPath,
				Description: folderDescriptionFromREADME(entryPath, entry.Name()),
				Extension:   ".dir",
				Icon:        folderIconFromREADME(entryPath, entry.Name()),
				DirCount:    dirCount,
				ScriptCount: scriptCount,
			})
			continue
		}

		name := entry.Name()
		if strings.HasPrefix(name, "example_") {
			continue
		}

		ext := filepath.Ext(name)
		valid := false
		if plat == "windows" {
			valid = ext == ".ps1" || ext == ".bat"
		} else {
			valid = ext == ".sh"
		}
		if !valid {
			continue
		}

		scripts = append(scripts, core.Script{
			Name:        name,
			Path:        entryPath,
			Description: extractDescription(entryPath),
			Extension:   ext,
		})
	}

	return core.SortScripts(scripts), nil
}

// countImmediateItems counts subdirectories and scripts directly inside folderPath.
func countImmediateItems(folderPath, plat string) (dirCount, scriptCount int) {
	entries, err := os.ReadDir(folderPath)
	if err != nil {
		return 0, 0
	}
	for _, entry := range entries {
		if entry.IsDir() {
			if !strings.EqualFold(entry.Name(), "lib") {
				dirCount++
			}
			continue
		}
		name := entry.Name()
		if strings.HasPrefix(name, "example_") {
			continue
		}
		ext := filepath.Ext(name)
		if plat == "windows" {
			if ext == ".ps1" || ext == ".bat" {
				scriptCount++
			}
		} else {
			if ext == ".sh" {
				scriptCount++
			}
		}
	}
	return
}
