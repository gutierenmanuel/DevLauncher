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

		categories = append(categories, Category{
			Name:        entry.Name(),
			Path:        categoryPath,
			Icon:        folderIconFromREADME(categoryPath, entry.Name()),
			Description: folderDescriptionFromREADME(categoryPath, entry.Name()),
			ScriptCount: len(items),
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
	firstUseful := ""
	secondUseful := ""

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		line = strings.TrimLeft(line, "#")
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		if firstUseful == "" {
			firstUseful = line
			continue
		}
		secondUseful = line
		break
	}

	if firstUseful == "" {
		return "", "", false
	}

	fields := strings.Fields(firstUseful)
	icon := ""
	desc := firstUseful
	if len(fields) > 0 && looksLikeEmojiToken(fields[0]) {
		icon = fields[0]
		desc = strings.TrimSpace(strings.TrimPrefix(firstUseful, fields[0]))
	}
	if desc == "" {
		desc = secondUseful
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
