package app

import (
	"path/filepath"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/launcher/core"
	"github.com/lucas/launcher/middleware"
)

// Model is the root BubbleTea application model.
type Model struct {
	state           core.ViewState
	rootDir         string
	staticDir       string
	scriptsRoot     string
	launchDir       string
	runDir          string
	currentVersion  string
	categories      []core.Category
	currentCategory core.Category
	currentPath     string
	scripts         []core.Script
	currentScript   core.Script
	categoryList    list.Model
	scriptList      list.Model
	commandMode     CommandMode
	err             error
	executing       bool
	executionResult int
	executionOutput string
	outputScroll    int
	width           int
	height          int
	headerShown     bool
	header          string
}

// NewModel creates and initialises a new application Model.
func NewModel() Model {
	rootDir, launchDir := middleware.ResolveRootDirWithLaunch()

	staticDir := middleware.GetStaticPath(rootDir)
	scriptsRoot := middleware.GetScriptsPath(rootDir)
	currentVersion := middleware.ReadLauncherVersion(rootDir)

	return Model{
		state:          core.CategoryView,
		rootDir:        rootDir,
		staticDir:      staticDir,
		scriptsRoot:    scriptsRoot,
		launchDir:      launchDir,
		runDir:         launchDir,
		currentVersion: currentVersion,
		commandMode:    NewCommandMode(),
		width:          80,
		height:         24,
	}
}

// Init fires the initial command to load categories.
func (m *Model) Init() tea.Cmd {
	return loadCategories(m.rootDir)
}

// Update handles incoming messages and keyboard/mouse events.
func (m *Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.commandMode.SetSize(msg.Width, msg.Height)
		return m, nil

	case tea.MouseMsg:
		if m.commandMode.active {
			return m, m.commandMode.HandleMouse(msg)
		}
		if m.state == core.ResultView {
			if msg.Type == tea.MouseWheelUp && m.outputScroll > 0 {
				m.outputScroll--
			} else if msg.Type == tea.MouseWheelDown {
				m.outputScroll++
			}
		}
		return m, nil

	case tea.KeyMsg:
		if m.commandMode.active {
			switch msg.String() {
			case "esc":
				m.commandMode.active = false
				m.commandMode.input.SetValue("")
				m.commandMode.output = ""
				return m, nil
			case "tab":
				m.commandMode.AutoComplete(m)
				return m, nil
			case "enter":
				cmd := m.commandMode.input.Value()
				m.commandMode.input.SetValue("")
				return m, m.commandMode.HandleCommand(cmd, m)
			default:
				var cmd tea.Cmd
				m.commandMode.input, cmd = m.commandMode.input.Update(msg)
				return m, cmd
			}
		}

		switch msg.String() {
		case ":":
			m.commandMode.active = true
			m.commandMode.SetSize(m.width, m.height)
			m.commandMode.input.Focus()
			return m, nil

		case ".":
			if m.state == core.ScriptView {
				if m.currentPath != "" && m.currentPath != m.currentCategory.Path {
					m.currentPath = filepath.Dir(m.currentPath)
					return m, loadScripts(m.currentPath)
				}
				m.state = core.CategoryView
				return m, nil
			} else if m.state == core.ResultView {
				m.state = core.ScriptView
				return m, nil
			} else if m.state == core.CategoryView {
				return m, tea.Quit
			}

		case "ctrl+c", "q":
			return m, tea.Quit

		case "esc", "0":
			if m.state == core.ScriptView {
				if m.currentPath != "" && m.currentPath != m.currentCategory.Path {
					m.currentPath = filepath.Dir(m.currentPath)
					return m, loadScripts(m.currentPath)
				}
				m.state = core.CategoryView
				return m, nil
			} else if m.state == core.ResultView {
				m.state = core.ScriptView
				return m, nil
			} else if m.state == core.CategoryView {
				return m, tea.Quit
			}

		case "enter":
			if m.state == core.CategoryView && len(m.categories) > 0 {
				if i, ok := m.categoryList.SelectedItem().(categoryItem); ok {
					m.currentCategory = m.categories[i.index]
					m.currentPath = m.currentCategory.Path
					m.state = core.ScriptView
					m.headerShown = true
					return m, loadScripts(m.currentPath)
				}
			} else if m.state == core.ScriptView && len(m.scripts) > 0 {
				if i, ok := m.scriptList.SelectedItem().(scriptItem); ok {
					m.currentScript = m.scripts[i.index]
					if m.currentScript.Extension == ".dir" {
						m.currentPath = m.currentScript.Path
						return m, loadScripts(m.currentPath)
					}
					m.state = core.ExecutingView
					m.outputScroll = 0
					return m, executeScript(m.currentScript, m.runDir)
				}
			} else if m.state == core.ResultView {
				m.state = core.ScriptView
				return m, nil
			}

		case "up", "k":
			if m.state == core.ResultView && m.outputScroll > 0 {
				m.outputScroll--
				return m, nil
			}
		case "down", "j":
			if m.state == core.ResultView {
				m.outputScroll++
				return m, nil
			}

		case "1", "2", "3", "4", "5", "6", "7", "8", "9":
			num := int(msg.String()[0]-'0') - 1
			if m.state == core.CategoryView && num >= 0 && num < len(m.categories) {
				m.currentCategory = m.categories[num]
				m.currentPath = m.currentCategory.Path
				m.state = core.ScriptView
				m.headerShown = true
				return m, loadScripts(m.currentPath)
			} else if m.state == core.ScriptView && num >= 0 && num < len(m.scripts) {
				m.currentScript = m.scripts[num]
				if m.currentScript.Extension == ".dir" {
					m.currentPath = m.currentScript.Path
					return m, loadScripts(m.currentPath)
				}
				m.state = core.ExecutingView
				return m, executeScript(m.currentScript, m.runDir)
			}
		}

	case categoriesLoadedMsg:
		m.categories = msg.categories
		m.categoryList = m.createCategoryList()
		return m, nil

	case scriptsLoadedMsg:
		m.scripts = msg.scripts
		m.scriptList = m.createScriptList()
		return m, nil

	case scriptExecutedMsg:
		m.executionResult = msg.exitCode
		m.executionOutput = msg.output
		m.executing = false
		m.state = core.ResultView
		return m, nil

	case errorMsg:
		m.err = msg.err
		return m, nil
	}

	// Delegate navigation to the active list
	var cmd tea.Cmd
	if m.state == core.CategoryView {
		m.categoryList, cmd = m.categoryList.Update(msg)
	} else if m.state == core.ScriptView {
		m.scriptList, cmd = m.scriptList.Update(msg)
	}

	return m, cmd
}

// --- Root directory resolution ---

// findRootDir returns the rootDir (exported for use in views.go).
func findRootDir() (string, error) {
	root, _ := middleware.ResolveRootDirWithLaunch()
	return root, nil
}
