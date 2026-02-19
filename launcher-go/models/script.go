package models

import (
	"bufio"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
)

// Script represents an executable script
type Script struct {
	Name        string
	Path        string
	Description string
	Extension   string
	Icon        string
}

// ScanScripts scans a directory for executable scripts
func ScanScripts(categoryPath string) ([]Script, error) {
	entries, err := os.ReadDir(categoryPath)
	if err != nil {
		return nil, err
	}

	var scripts []Script
	platform := runtime.GOOS

	for _, entry := range entries {
		entryPath := filepath.Join(categoryPath, entry.Name())

		if entry.IsDir() {
			if strings.EqualFold(entry.Name(), "lib") {
				continue
			}

			scripts = append(scripts, Script{
				Name:        entry.Name(),
				Path:        entryPath,
				Description: folderDescriptionFromREADME(entryPath, entry.Name()),
				Extension:   ".dir",
				Icon:        folderIconFromREADME(entryPath, entry.Name()),
			})
			continue
		}

		name := entry.Name()
		if strings.HasPrefix(name, "example_") {
			continue
		}

		ext := filepath.Ext(name)
		isValid := false
		if platform == "windows" {
			isValid = ext == ".ps1" || ext == ".bat"
		} else {
			isValid = ext == ".sh"
		}
		if !isValid {
			continue
		}

		scripts = append(scripts, Script{
			Name:        name,
			Path:        entryPath,
			Description: extractDescription(entryPath),
			Extension:   ext,
		})
	}

	// Sort folders first, then scripts, alphabetically.
	sort.Slice(scripts, func(i, j int) bool {
		iDir := scripts[i].Extension == ".dir"
		jDir := scripts[j].Extension == ".dir"
		if iDir != jDir {
			return iDir
		}
		return scripts[i].Name < scripts[j].Name
	})

	return scripts, nil
}

// extractDescription extracts the description from script comments
func extractDescription(scriptPath string) string {
	file, err := os.Open(scriptPath)
	if err != nil {
		return "Sin descripción"
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineCount := 0
	
	// Read first 5 lines
	for scanner.Scan() && lineCount < 5 {
		line := strings.TrimSpace(scanner.Text())
		lineCount++

		// Skip shebang and empty lines
		if strings.HasPrefix(line, "#!") || line == "" {
			continue
		}

		// Look for comment with description
		if strings.HasPrefix(line, "#") {
			// Remove comment marker
			desc := strings.TrimPrefix(line, "#")
			desc = strings.TrimSpace(desc)
			
			// Remove common prefixes
			desc = strings.TrimPrefix(desc, "Script:")
			desc = strings.TrimPrefix(desc, "Script para")
			desc = strings.TrimPrefix(desc, "Descripción:")
			desc = strings.TrimPrefix(desc, "Description:")
			desc = strings.TrimSpace(desc)

			if desc != "" {
				return desc
			}
		}
	}

	// Fallback: use filename
	name := filepath.Base(scriptPath)
	name = strings.TrimSuffix(name, filepath.Ext(name))
	name = strings.ReplaceAll(name, "_", " ")
	return name
}
