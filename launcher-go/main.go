package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/launcher/models"
)

func main() {
	// Parse CLI arguments
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "-h", "--help":
			showHelp()
			return
		case "-l", "--list":
			models.ListAllScripts()
			return
		default:
			fmt.Printf("Unknown option: %s\n", os.Args[1])
			fmt.Println("Use --help to see available options")
			os.Exit(1)
		}
	}

	// Start interactive TUI
	model := models.NewModel()
	p := tea.NewProgram(&model, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}

func showHelp() {
	fmt.Println("Launcher - Universal Development Scripts Launcher")
	fmt.Println()
	fmt.Println("Usage: launcher [options]")
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  (no options)    Show interactive hierarchical menu")
	fmt.Println("  -l, --list      List all organized scripts")
	fmt.Println("  -h, --help      Show this help")
	fmt.Println()
	fmt.Println("Navigation:")
	fmt.Println("  1. Select a category (build, dev, installers, etc.)")
	fmt.Println("  2. Select a script within the category")
	fmt.Println("  3. The script runs automatically")
	fmt.Println()
	fmt.Println("Controls:")
	fmt.Println("  ↑/↓ or j/k      Navigate")
	fmt.Println("  Enter           Select")
	fmt.Println("  Esc or q        Back/Quit")
	fmt.Println()
}
