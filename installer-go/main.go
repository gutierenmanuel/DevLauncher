package main

import (
	"fmt"
	"os"
	"os/exec"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/installer/tui"
)

func main() {
	m := tui.NewModel(assetsFS)
	p := tea.NewProgram(&m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}

	if fm, ok := finalModel.(*tui.Model); ok && fm.ShouldLaunch() {
		cmd := exec.Command(fm.LaunchPath())
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Fprintln(os.Stderr, "No se pudo iniciar DevLauncher:", err)
			os.Exit(1)
		}
	}
}
