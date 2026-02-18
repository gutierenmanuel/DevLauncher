package ui

import tea "github.com/charmbracelet/bubbletea"

// Messages for Bubbletea
type (
	CategoriesLoadedMsg struct {
		Categories []CategoryListItem
	}

	ScriptsLoadedMsg struct {
		Scripts []ScriptListItem
	}

	ScriptExecutedMsg struct {
		ExitCode int
		ScriptName string
	}

	ErrorMsg struct {
		Err error
	}
)

// CategoryListItem represents a category for the list
type CategoryListItem struct {
	Name        string
	Icon        string
	Description string
	ScriptCount int
}

// ScriptListItem represents a script for the list
type ScriptListItem struct {
	Name        string
	Description string
	Path        string
	Extension   string
}

// Bubbletea list item interface implementations
func (i CategoryListItem) FilterValue() string { return i.Name }
func (i ScriptListItem) FilterValue() string { return i.Name }

// LoadCategoriesCmd loads categories in the background
func LoadCategoriesCmd(rootDir string) tea.Cmd {
	return func() tea.Msg {
		// This will be implemented in app.go
		return nil
	}
}

// LoadScriptsCmd loads scripts for a category
func LoadScriptsCmd(categoryPath string) tea.Cmd {
	return func() tea.Msg {
		// This will be implemented in app.go
		return nil
	}
}

// ExecuteScriptCmd executes a script
func ExecuteScriptCmd(scriptPath, scriptName, ext string) tea.Cmd {
	return func() tea.Msg {
		// This will be implemented in app.go
		return nil
	}
}
