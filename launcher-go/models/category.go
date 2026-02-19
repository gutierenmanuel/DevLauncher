package models

import (
	"bufio"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"unicode"

	"github.com/lucas/launcher/utils"
)

// Category represents a script category
type Category struct {
	Name        string
	Path        string
	Icon        string
	Description string
	DirCount    int
	ScriptCount int
}

// ScanCategories scans the scripts directory and returns all categories
func ScanCategories(rootDir string) ([]Category, error) {
	scriptsPath := utils.GetScriptsPath(rootDir)
	entries, err := os.ReadDir(scriptsPath)
	if err != nil {
		return nil, err
	}

	var categories []Category
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		if strings.EqualFold(entry.Name(), "lib") {
			continue
		}

		categoryPath := filepath.Join(scriptsPath, entry.Name())
		items, scanErr := ScanScripts(categoryPath)
		if scanErr != nil {
			continue
		}
		if len(items) == 0 {
			continue
		}

		dirCount := 0
		scriptCount := 0
		for _, item := range items {
			if item.Extension == ".dir" {
				dirCount++
			} else {
				scriptCount++
			}
		}

		categories = append(categories, Category{
			Name:        entry.Name(),
			Path:        categoryPath,
			Icon:        folderIconFromREADME(categoryPath, entry.Name()),
			Description: folderDescriptionFromREADME(categoryPath, entry.Name()),
			DirCount:    dirCount,
			ScriptCount: scriptCount,
		})
	}

	// Sort categories alphabetically
	sort.Slice(categories, func(i, j int) bool {
		return categories[i].Name < categories[j].Name
	})

	return categories, nil
}

func folderDescriptionFromREADME(folderPath, fallback string) string {
	_, desc, ok := readmeFolderMeta(folderPath)
	if !ok || strings.TrimSpace(desc) == "" {
		return utils.CategoryDescription(fallback)
	}
	return desc
}

func folderIconFromREADME(folderPath, fallback string) string {
	icon, _, ok := readmeFolderMeta(folderPath)
	if ok && icon != "" {
		return icon
	}
	return utils.CategoryIcon(fallback)
}

func readmeFolderMeta(folderPath string) (string, string, bool) {
	entries, err := os.ReadDir(folderPath)
	if err != nil {
		return "", "", false
	}

	readmePath := ""
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		nameLower := strings.ToLower(entry.Name())
		if strings.HasPrefix(nameLower, "readme") {
			readmePath = filepath.Join(folderPath, entry.Name())
			break
		}
	}
	if readmePath == "" {
		return "", "", false
	}

	f, openErr := os.Open(readmePath)
	if openErr != nil {
		return "", "", false
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	lines := make([]string, 0)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	headerIndex := -1
	headerText := ""
	for i, raw := range lines {
		trimmed := strings.TrimSpace(raw)
		if trimmed == "" {
			continue
		}
		if strings.HasPrefix(trimmed, "#") {
			headerIndex = i
			headerText = strings.TrimSpace(strings.TrimLeft(trimmed, "#"))
			break
		}
	}

	if headerIndex == -1 || headerText == "" {
		return "", "", false
	}

	fields := strings.Fields(headerText)
	icon := ""
	if len(fields) > 0 && looksLikeEmojiToken(fields[0]) {
		icon = fields[0]
	}

	desc := ""
	for i := headerIndex + 1; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])
		if line == "" {
			continue
		}
		if strings.HasPrefix(line, "#") {
			continue
		}
		desc = line
		break
	}

	if len(fields) > 0 && looksLikeEmojiToken(fields[0]) {
		_ = fields[0]
	}

	return icon, desc, true
}

func looksLikeEmojiToken(token string) bool {
	token = strings.TrimSpace(token)
	if token == "" {
		return false
	}
	runes := []rune(token)
	if len(runes) > 6 {
		return false
	}
	hasSymbol := false
	for _, r := range runes {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			return false
		}
		if unicode.IsPunct(r) {
			continue
		}
		if _, err := strconv.Unquote("'" + string(r) + "'"); err == nil {
			hasSymbol = true
		}
	}
	return hasSymbol
}
