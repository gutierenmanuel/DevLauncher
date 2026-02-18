package ui

import (
	"bufio"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"
)

// LoadASCIIArt loads a random ASCII art from static/ and applies gradient
func LoadASCIIArt(staticPath string) string {
	// Find all .txt files in static directory
	files, err := ioutil.ReadDir(staticPath)
	if err != nil {
		return RenderFallbackHeader()
	}

	// Filter .txt files
	var txtFiles []string
	for _, f := range files {
		if !f.IsDir() && strings.HasSuffix(f.Name(), ".txt") {
			txtFiles = append(txtFiles, f.Name())
		}
	}

	if len(txtFiles) == 0 {
		return RenderFallbackHeader()
	}

	// Select random file
	rand.Seed(time.Now().UnixNano())
	selectedFile := txtFiles[rand.Intn(len(txtFiles))]
	asciiPath := filepath.Join(staticPath, selectedFile)

	file, err := os.Open(asciiPath)
	if err != nil {
		return RenderFallbackHeader()
	}
	defer file.Close()

	// Read all lines
	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if len(lines) == 0 {
		return RenderFallbackHeader()
	}

	// Apply gradient colors
	return ApplyGradient(lines)
}

// ApplyGradient applies a color gradient to ASCII art lines
func ApplyGradient(lines []string) string {
	var result strings.Builder
	totalLines := len(lines)

	// Define gradient colors (purple to cyan to pink)
	gradientColors := []lipgloss.Color{
		lipgloss.Color("#9b59b6"), // Purple
		lipgloss.Color("#8e44ad"),
		lipgloss.Color("#3498db"), // Blue
		lipgloss.Color("#2980b9"),
		lipgloss.Color("#1abc9c"), // Cyan
		lipgloss.Color("#16a085"),
		lipgloss.Color("#e74c3c"), // Pink/Red
		lipgloss.Color("#c0392b"),
	}

	for i, line := range lines {
		// Calculate color index based on line position
		colorIndex := (i * len(gradientColors)) / totalLines
		if colorIndex >= len(gradientColors) {
			colorIndex = len(gradientColors) - 1
		}

		color := gradientColors[colorIndex]
		styledLine := lipgloss.NewStyle().Foreground(color).Render(line)
		result.WriteString(styledLine)
		result.WriteString("\n")
	}

	// Add spacing after header
	result.WriteString("\n")

	return result.String()
}

// RenderFallbackHeader renders a simple header if ASCII art file is not found
func RenderFallbackHeader() string {
	var result strings.Builder
	
	width := 58
	topLine := BoxStyle.Render(BoxTL + strings.Repeat(BoxH, width) + BoxTR)
	midLine := BoxStyle.Render(BoxV) + "  🚀 Lanzador Universal de Scripts" + strings.Repeat(" ", width-34) + BoxStyle.Render(BoxV)
	botLine := BoxStyle.Render(BoxBL + strings.Repeat(BoxH, width) + BoxBR)
	
	result.WriteString(topLine + "\n")
	result.WriteString(midLine + "\n")
	result.WriteString(botLine + "\n")
	result.WriteString("\n") // Add spacing
	
	return result.String()
}

// RenderBreadcrumb renders the navigation breadcrumb with project path
func RenderBreadcrumb(items []string, rootDir string) string {
	var result strings.Builder
	
	// Show project path first
	result.WriteString(DimStyle.Render("📂 " + rootDir) + "\n")
	
	if len(items) == 0 {
		return result.String()
	}
	
	// Then show navigation breadcrumb
	breadcrumb := BreadcrumbStyle.Render("┌─ " + strings.Join(items, " > "))
	result.WriteString(breadcrumb + "\n")
	
	return result.String()
}
