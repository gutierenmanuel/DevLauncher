package middleware

import (
	"bufio"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"unicode"

	"github.com/lucas/launcher/core"
)

// ReadLauncherVersion reads the version string from VERSION.txt in rootDir.
// Returns an empty string if the file is missing or malformed.
func ReadLauncherVersion(rootDir string) string {
	data, err := os.ReadFile(filepath.Join(rootDir, "VERSION.txt"))
	if err != nil {
		return ""
	}
	line := strings.SplitN(strings.TrimSpace(string(data)), "\n", 2)[0]
	fields := strings.Fields(line)
	if len(fields) == 0 {
		return ""
	}
	return fields[0]
}

// extractDescription parses a script file and returns the first meaningful comment.
func extractDescription(scriptPath string) string {
	file, err := os.Open(scriptPath)
	if err != nil {
		return "Sin descripción"
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineCount := 0
	for scanner.Scan() && lineCount < 5 {
		line := strings.TrimSpace(scanner.Text())
		lineCount++

		if strings.HasPrefix(line, "#!") || line == "" {
			continue
		}
		if strings.HasPrefix(line, "#") {
			desc := strings.TrimSpace(strings.TrimPrefix(line, "#"))
			desc = strings.TrimSpace(strings.TrimPrefix(desc, "Script:"))
			desc = strings.TrimSpace(strings.TrimPrefix(desc, "Script para"))
			desc = strings.TrimSpace(strings.TrimPrefix(desc, "Descripción:"))
			desc = strings.TrimSpace(strings.TrimPrefix(desc, "Description:"))
			if desc != "" {
				return desc
			}
		}
	}

	name := filepath.Base(scriptPath)
	name = strings.TrimSuffix(name, filepath.Ext(name))
	return strings.ReplaceAll(name, "_", " ")
}

// readmeFolderMeta reads the README in folderPath and extracts (icon, description).
func readmeFolderMeta(folderPath string) (icon, desc string, ok bool) {
	entries, err := os.ReadDir(folderPath)
	if err != nil {
		return "", "", false
	}

	readmePath := ""
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		if strings.HasPrefix(strings.ToLower(entry.Name()), "readme") {
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

	var lines []string
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		lines = append(lines, sc.Text())
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
	if len(fields) > 0 && looksLikeEmojiToken(fields[0]) {
		icon = fields[0]
	}

	for i := headerIndex + 1; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		desc = line
		break
	}

	return icon, desc, true
}

// folderIconFromREADME returns the icon from README or falls back to core.CategoryIcon.
func folderIconFromREADME(folderPath, fallback string) string {
	icon, _, ok := readmeFolderMeta(folderPath)
	if ok && icon != "" {
		return icon
	}
	return core.CategoryIcon(fallback)
}

// folderDescriptionFromREADME returns the description from README or falls back to core.CategoryDescription.
func folderDescriptionFromREADME(folderPath, fallback string) string {
	_, desc, ok := readmeFolderMeta(folderPath)
	if ok && strings.TrimSpace(desc) != "" {
		return desc
	}
	return core.CategoryDescription(fallback)
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
