package models

import (
	"bufio"
	"io/ioutil"
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
}

// ScanScripts scans a directory for executable scripts
func ScanScripts(categoryPath string) ([]Script, error) {
	entries, err := ioutil.ReadDir(categoryPath)
	if err != nil {
		return nil, err
	}

	var scripts []Script
	platform := runtime.GOOS
	
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		
		// Skip example scripts
		if strings.HasPrefix(name, "example_") {
			continue
		}

		ext := filepath.Ext(name)
		
		// Filter by platform
		isValid := false
		if platform == "windows" {
			isValid = ext == ".ps1" || ext == ".bat"
		} else {
			isValid = ext == ".sh"
		}

		if !isValid {
			continue
		}

		scriptPath := filepath.Join(categoryPath, name)
		description := extractDescription(scriptPath)

		scripts = append(scripts, Script{
			Name:        name,
			Path:        scriptPath,
			Description: description,
			Extension:   ext,
		})
	}

	// Sort scripts alphabetically
	sort.Slice(scripts, func(i, j int) bool {
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
