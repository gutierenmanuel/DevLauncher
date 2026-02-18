package models

import (
	"io/ioutil"
	"path/filepath"
	"sort"

	"github.com/lucas/launcher/utils"
)

// Category represents a script category
type Category struct {
	Name        string
	Path        string
	Icon        string
	Description string
	ScriptCount int
}

// ScanCategories scans the scripts directory and returns all categories
func ScanCategories(rootDir string) ([]Category, error) {
	scriptsPath := utils.GetScriptsPath(rootDir)
	
	entries, err := ioutil.ReadDir(scriptsPath)
	if err != nil {
		return nil, err
	}

	var categories []Category
	
	for _, entry := range entries {
		if !entry.IsDir() || entry.Name() == "lib" {
			continue
		}

		categoryPath := filepath.Join(scriptsPath, entry.Name())
		scripts, err := ScanScripts(categoryPath)
		if err != nil {
			continue
		}

		// Only include categories with scripts
		if len(scripts) > 0 {
			categories = append(categories, Category{
				Name:        entry.Name(),
				Path:        categoryPath,
				Icon:        utils.CategoryIcon(entry.Name()),
				Description: utils.CategoryDescription(entry.Name()),
				ScriptCount: len(scripts),
			})
		}
	}

	// Sort categories alphabetically
	sort.Slice(categories, func(i, j int) bool {
		return categories[i].Name < categories[j].Name
	})

	return categories, nil
}
