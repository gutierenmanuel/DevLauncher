package middleware

import (
	"bufio"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/lucas/launcher/core"
)

// LoadASCIIArt reads a random .txt file from staticPath and returns it
// rendered with a color gradient via core.ApplyGradient.
// Falls back to an empty string if no files are found.
func LoadASCIIArt(staticPath string) string {
	files, err := os.ReadDir(staticPath)
	if err != nil {
		return ""
	}

	var txtFiles []string
	for _, f := range files {
		if !f.IsDir() && strings.HasSuffix(f.Name(), ".txt") {
			txtFiles = append(txtFiles, f.Name())
		}
	}
	if len(txtFiles) == 0 {
		return ""
	}

	//nolint:gosec // non-security random selection
	rand.Seed(time.Now().UnixNano())
	selected := txtFiles[rand.Intn(len(txtFiles))]

	file, err := os.Open(filepath.Join(staticPath, selected))
	if err != nil {
		return ""
	}
	defer file.Close()

	var lines []string
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		lines = append(lines, sc.Text())
	}

	if len(lines) == 0 {
		return ""
	}
	return core.ApplyGradient(lines)
}
