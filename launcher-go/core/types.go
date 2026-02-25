package core

// ViewState represents the current view in the TUI
type ViewState int

const (
	CategoryView ViewState = iota
	ScriptView
	ExecutingView
	ResultView
)

// Category represents a script category (folder)
type Category struct {
	Name        string
	Path        string
	Icon        string
	Description string
	DirCount    int
	ScriptCount int
}

// Script represents an executable script or subdirectory
type Script struct {
	Name        string
	Path        string
	Description string
	Extension   string
	Icon        string
	DirCount    int
	ScriptCount int
}
