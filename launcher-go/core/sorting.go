package core

import "sort"

// SortCategories sorts categories alphabetically by name.
// Returns a new slice; the original is not mutated.
func SortCategories(cats []Category) []Category {
	result := make([]Category, len(cats))
	copy(result, cats)
	sort.Slice(result, func(i, j int) bool {
		return result[i].Name < result[j].Name
	})
	return result
}

// SortScripts sorts scripts: directories first, then alphabetically.
// Returns a new slice; the original is not mutated.
func SortScripts(scripts []Script) []Script {
	result := make([]Script, len(scripts))
	copy(result, scripts)
	sort.Slice(result, func(i, j int) bool {
		iDir := result[i].Extension == ".dir"
		jDir := result[j].Extension == ".dir"
		if iDir != jDir {
			return iDir
		}
		return result[i].Name < result[j].Name
	})
	return result
}
