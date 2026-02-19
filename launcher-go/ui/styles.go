package ui

import (
	"github.com/charmbracelet/lipgloss"
)

// Color definitions matching the original launcher
var (
	ColorPurple  = lipgloss.Color("#af87ff")
	ColorCyan    = lipgloss.Color("#00d7ff")
	ColorYellow  = lipgloss.Color("#ffff00")
	ColorRed     = lipgloss.Color("#ff0000")
	ColorGreen   = lipgloss.Color("#00ff00")
	ColorBlue    = lipgloss.Color("#5f87ff")
	ColorGray    = lipgloss.Color("#808080")
	ColorDimGray = lipgloss.Color("#6c6c6c")
)

// Box drawing characters
const (
	BoxTL  = "╔"
	BoxTR  = "╗"
	BoxBL  = "╚"
	BoxBR  = "╝"
	BoxH   = "═"
	BoxV   = "║"
	BoxML  = "╠"
	BoxMR  = "╣"
	BoxSep = "─"
)

// Style definitions
var (
	TitleStyle = lipgloss.NewStyle().
			Foreground(ColorYellow).
			Bold(true)

	SubtitleStyle = lipgloss.NewStyle().
			Foreground(ColorGray)

	SelectedStyle = lipgloss.NewStyle().
			Foreground(ColorCyan).
			Bold(true)

	NormalStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("252"))

	DimStyle = lipgloss.NewStyle().
			Foreground(ColorDimGray)

	SuccessStyle = lipgloss.NewStyle().
			Foreground(ColorGreen).
			Bold(true)

	ErrorStyle = lipgloss.NewStyle().
			Foreground(ColorRed).
			Bold(true)

	BoxStyle = lipgloss.NewStyle().
			Foreground(ColorCyan)

	BreadcrumbStyle = lipgloss.NewStyle().
			Foreground(ColorDimGray)

	IconStyle = lipgloss.NewStyle().
			Foreground(ColorPurple)

	DirectoryStyle = lipgloss.NewStyle().
			Foreground(ColorBlue).
			Bold(true)

	ExecutableStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("252"))

	SelectedDirectoryStyle = lipgloss.NewStyle().
			Foreground(ColorCyan).
			Bold(true)

	SelectedExecutableStyle = lipgloss.NewStyle().
			Foreground(ColorGreen).
			Bold(true)

	HeaderVersionStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#c0392b")).
			Bold(true)
)

// DrawBox draws a box with content
func DrawBox(content string, width int) string {
	topLine := BoxStyle.Render(BoxTL + lipgloss.NewStyle().Render(lipgloss.PlaceHorizontal(width-2, lipgloss.Left, BoxH, lipgloss.WithWhitespaceChars(BoxH))) + BoxTR)
	bottomLine := BoxStyle.Render(BoxBL + lipgloss.NewStyle().Render(lipgloss.PlaceHorizontal(width-2, lipgloss.Left, BoxH, lipgloss.WithWhitespaceChars(BoxH))) + BoxBR)
	
	return topLine + "\n" + content + "\n" + bottomLine
}

// DrawSeparator draws a horizontal separator
func DrawSeparator(width int) string {
	return DimStyle.Render(lipgloss.PlaceHorizontal(width, lipgloss.Left, BoxSep, lipgloss.WithWhitespaceChars(BoxSep)))
}
