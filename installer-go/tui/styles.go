package tui

import "github.com/charmbracelet/lipgloss"

const (
	ColorPurple = "#af87ff"
	ColorCyan   = "#00d7ff"
	ColorYellow = "#ffff00"
	ColorGreen  = "#00ff00"
	ColorRed    = "#ff0000"
	ColorGray   = "#808080"
)

var (
	TitleStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color(ColorYellow)).
			Bold(true)

	SuccessStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color(ColorGreen)).
			Bold(true)

	ErrorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color(ColorRed)).
			Bold(true)

	DimStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color(ColorGray))

	NormalStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("252"))

	BoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color(ColorCyan)).
			Padding(1, 2)

	CyanStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color(ColorCyan))

	PurpleStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color(ColorPurple))
)
