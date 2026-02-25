package app

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/launcher/core"
	"github.com/lucas/launcher/middleware"
)

// --- Message types ---

type categoriesLoadedMsg struct {
	categories []core.Category
}

type scriptsLoadedMsg struct {
	scripts []core.Script
}

type scriptExecutedMsg struct {
	exitCode int
	output   string
}

type errorMsg struct {
	err error
}

// --- Command factories ---

func loadCategories(rootDir string) tea.Cmd {
	return func() tea.Msg {
		cats, err := middleware.ScanCategories(rootDir)
		if err != nil {
			return errorMsg{err}
		}
		return categoriesLoadedMsg{categories: cats}
	}
}

func loadScripts(categoryPath string) tea.Cmd {
	return func() tea.Msg {
		scripts, err := middleware.ScanScripts(categoryPath)
		if err != nil {
			return errorMsg{err}
		}
		return scriptsLoadedMsg{scripts: scripts}
	}
}

func executeScript(script core.Script, workingDir string) tea.Cmd {
	return tea.ExecProcess(middleware.BuildScriptCommand(script, workingDir), func(err error) tea.Msg {
		exitCode, output := middleware.ExecuteScript(script, workingDir)
		return scriptExecutedMsg{exitCode: exitCode, output: output}
	})
}
