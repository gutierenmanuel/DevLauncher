package core

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// gradientColors defines the color palette applied line by line to ASCII art.
var gradientColors = []lipgloss.Color{
	lipgloss.Color("#9b59b6"), // Purple
	lipgloss.Color("#8e44ad"),
	lipgloss.Color("#3498db"), // Blue
	lipgloss.Color("#2980b9"),
	lipgloss.Color("#1abc9c"), // Cyan
	lipgloss.Color("#16a085"),
	lipgloss.Color("#e74c3c"), // Pink/Red
	lipgloss.Color("#c0392b"),
}

// ApplyGradient applies a color gradient to a slice of ASCII art lines.
// Pure: takes []string, returns string — no I/O.
func ApplyGradient(lines []string) string {
	var result strings.Builder
	totalLines := len(lines)
	if totalLines == 0 {
		return ""
	}

	for i, line := range lines {
		colorIndex := (i * len(gradientColors)) / totalLines
		if colorIndex >= len(gradientColors) {
			colorIndex = len(gradientColors) - 1
		}
		color := gradientColors[colorIndex]
		styledLine := lipgloss.NewStyle().Foreground(color).Render(line)
		result.WriteString(styledLine)
		result.WriteString("\n")
	}

	result.WriteString("\n")
	return result.String()
}
