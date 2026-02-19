package models

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/list"
	"github.com/lucas/launcher/ui"
	"github.com/lucas/launcher/utils"
)

// ViewState represents the current view
type ViewState int

const (
	CategoryView ViewState = iota
	ScriptView
	ExecutingView
	ResultView
)

// Model is the Bubbletea application model
type Model struct {
	state            ViewState
	rootDir          string
	staticDir        string
	scriptsRoot      string
	currentVersion   string
	categories       []Category
	currentCategory  Category
	currentPath      string
	scripts          []Script
	currentScript    Script
	categoryList     list.Model
	scriptList       list.Model
	commandMode      CommandMode
	err              error
	executing        bool
	executionResult  int
	executionError   string  // Error message from script execution
	width            int
	height           int
	headerShown      bool
	header           string  // Cached header (loaded once)
}

// NewModel creates a new application model
func NewModel() Model {
	// Get root directory - try multiple strategies
	var rootDir string
	
	// Strategy 1: Check if scripts/ exists in parent of current dir
	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "..", "scripts")); err == nil {
			rootDir, _ = filepath.Abs("..")
		} else if _, err := os.Stat(filepath.Join(cwd, "scripts")); err == nil {
			rootDir = cwd
		}
	}
	
	// Strategy 2: Use executable path
	if rootDir == "" {
		execPath, _ := os.Executable()
		realPath, _ := filepath.EvalSymlinks(execPath)
		rootDir = filepath.Dir(realPath)
	}

	staticDir := utils.GetStaticPath(rootDir)
	scriptsRoot := utils.GetScriptsPath(rootDir)
	currentVersion := readLauncherVersion(rootDir)

	return Model{
		state:       CategoryView,
		rootDir:     rootDir,
		staticDir:   staticDir,
		scriptsRoot: scriptsRoot,
		currentVersion: currentVersion,
		commandMode: NewCommandMode(),
		width:       80,
		height:      24,
	}
}

// Init initializes the model
func (m *Model) Init() tea.Cmd {
	return loadCategories(m.rootDir)
}

// Update handles messages
func (m *Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		// Handle command mode first
		if m.commandMode.active {
			switch msg.String() {
			case "esc":
				m.commandMode.active = false
				m.commandMode.input.SetValue("")
				m.commandMode.output = ""
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
			// Activate command mode with ':'
			m.commandMode.active = true
			m.commandMode.input.Focus()
			return m, nil
		
		case ".":
			// '.' goes back one level
			if m.state == ScriptView {
				if m.currentPath != "" && m.currentPath != m.currentCategory.Path {
					m.currentPath = filepath.Dir(m.currentPath)
					return m, loadScripts(m.currentPath)
				}
				m.state = CategoryView
				return m, nil
			} else if m.state == ResultView {
				m.state = ScriptView
				return m, nil
			} else if m.state == CategoryView {
				return m, tea.Quit  // Exit from main menu
			}
		
		case "ctrl+c", "q":
			// Always quit regardless of state
			return m, tea.Quit

		case "esc", "0":
			// Go back one level (or quit from main menu)
			if m.state == ScriptView {
				if m.currentPath != "" && m.currentPath != m.currentCategory.Path {
					m.currentPath = filepath.Dir(m.currentPath)
					return m, loadScripts(m.currentPath)
				}
				m.state = CategoryView
				return m, nil
			} else if m.state == ResultView {
				m.state = ScriptView
				return m, nil
			} else if m.state == CategoryView {
				return m, tea.Quit
			}

		case "enter":
			if m.state == CategoryView && len(m.categories) > 0 {
				// Get selected category
				if i, ok := m.categoryList.SelectedItem().(categoryItem); ok {
					m.currentCategory = m.categories[i.index]
					m.currentPath = m.currentCategory.Path
					m.state = ScriptView
					m.headerShown = true  // Mark header as shown when leaving CategoryView
					return m, loadScripts(m.currentPath)
				}
			} else if m.state == ScriptView && len(m.scripts) > 0 {
				// Get selected script
				if i, ok := m.scriptList.SelectedItem().(scriptItem); ok {
					m.currentScript = m.scripts[i.index]
					if m.currentScript.Extension == ".dir" {
						m.currentPath = m.currentScript.Path
						return m, loadScripts(m.currentPath)
					}
					m.state = ExecutingView
					return m, executeScript(m.currentScript)
				}
			} else if m.state == ResultView {
				// Return to script view after seeing result
				m.state = ScriptView
				return m, nil
			}
		
		// Number keys for quick selection
		case "1", "2", "3", "4", "5", "6", "7", "8", "9":
			num := int(msg.String()[0] - '0') - 1
			if m.state == CategoryView && num >= 0 && num < len(m.categories) {
				m.currentCategory = m.categories[num]
				m.currentPath = m.currentCategory.Path
				m.state = ScriptView
				m.headerShown = true  // Mark header as shown when leaving CategoryView
				return m, loadScripts(m.currentPath)
			} else if m.state == ScriptView && num >= 0 && num < len(m.scripts) {
				m.currentScript = m.scripts[num]
				if m.currentScript.Extension == ".dir" {
					m.currentPath = m.currentScript.Path
					return m, loadScripts(m.currentPath)
				}
				m.state = ExecutingView
				return m, executeScript(m.currentScript)
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
		m.executionError = msg.errorOutput
		m.executing = false
		m.state = ResultView
		return m, nil

	case errorMsg:
		m.err = msg.err
		return m, nil
	}

	// Update lists
	var cmd tea.Cmd
	if m.state == CategoryView {
		m.categoryList, cmd = m.categoryList.Update(msg)
	} else if m.state == ScriptView {
		m.scriptList, cmd = m.scriptList.Update(msg)
	}

	return m, cmd
}

// View renders the UI
func (m *Model) View() string {
	switch m.state {
	case CategoryView:
		return m.renderCategoryView()
	case ScriptView:
		return m.renderScriptView()
	case ExecutingView:
		return m.renderExecutingView()
	case ResultView:
		return m.renderResultView()
	}

	return ""
}

func (m *Model) renderCategoryView() string {
	// Load and cache header on first render
	if m.header == "" && len(m.categories) > 0 {
		m.header = decorateHeaderWithVersion(ui.LoadASCIIArt(m.staticDir), m.currentVersion)
	}
	
	// Show header while in CategoryView (until user navigates away)
	header := ""
	if !m.headerShown && len(m.categories) > 0 {
		header = m.header
	}
	
	breadcrumb := ui.RenderBreadcrumb([]string{"Inicio"}, m.rootDir)
	
	content := header + breadcrumb
	
	if len(m.categories) == 0 {
		content += ui.ErrorStyle.Render("✗ No se encontraron categorías") + "\n"
	} else {
		content += ui.TitleStyle.Render("Selecciona una categoría") + "\n"
		content += m.renderCategoriesWithNumbers()
	}
	
	content += "\n" + ui.DimStyle.Render("1-9/↑↓/j/k: navegar  enter/número: seleccionar  :: terminal  ./0/esc: volver  q: salir")
	
	if m.commandMode.active {
		content += m.commandMode.View()
	}
	
	return content
}

func (m Model) renderCategoriesWithNumbers() string {
	var result string
	for i, cat := range m.categories {
		if i >= 9 {
			break // Only show first 9 with numbers
		}
		num := i + 1
		selected := m.categoryList.Index() == i

		label := fmt.Sprintf("%s %s/", cat.Icon, cat.Name)
		prefix := fmt.Sprintf("  [%d] ", num)
		var styledLabel string
		if selected {
			styledLabel = ui.SelectedDirectoryStyle.Render(label)
		} else {
			styledLabel = ui.DirectoryStyle.Render(label)
		}

		if selected {
			result += ui.SelectedStyle.Render(prefix) + styledLabel + "\n"
			result += ui.DimStyle.Render(fmt.Sprintf("      %s (%d script(s))", cat.Description, cat.ScriptCount)) + "\n"
		} else {
			result += ui.NormalStyle.Render(prefix) + styledLabel + "\n"
			result += ui.DimStyle.Render(fmt.Sprintf("      %s (%d script(s))", cat.Description, cat.ScriptCount)) + "\n"
		}
	}
	return result
}

func (m Model) renderScriptView() string {
	breadcrumbParts := []string{"Inicio", m.currentCategory.Name}
	if m.currentPath != "" {
		if rel, err := filepath.Rel(m.currentCategory.Path, m.currentPath); err == nil {
			rel = filepath.ToSlash(rel)
			if rel != "." && rel != "" {
				for _, p := range strings.Split(rel, "/") {
					if strings.TrimSpace(p) != "" {
						breadcrumbParts = append(breadcrumbParts, p)
					}
				}
			}
		}
	}
	breadcrumb := ui.RenderBreadcrumb(breadcrumbParts, m.rootDir)
	
	content := breadcrumb
	title := filepath.Base(m.currentPath)
	if title == "." || title == string(filepath.Separator) || title == "" {
		title = m.currentCategory.Name
	}
	content += fmt.Sprintf("%s  %s\n", m.currentCategory.Icon, ui.TitleStyle.Render(title))
	content += ui.DimStyle.Render(fmt.Sprintf("%d item(s) disponible(s)", len(m.scripts))) + "\n"
	
	if len(m.scripts) == 0 {
		content += ui.ErrorStyle.Render("✗ No se encontraron elementos en esta carpeta") + "\n"
	} else {
		content += m.renderScriptsWithNumbers()
	}
	
	content += "\n" + ui.DimStyle.Render("1-9/↑↓/j/k: navegar  enter/número: abrir/ejecutar  :: terminal  ./0/esc: volver  q: salir")
	
	if m.commandMode.active {
		content += m.commandMode.View()
	}
	
	return content
}

func (m Model) renderScriptsWithNumbers() string {
	var result string
	for i, script := range m.scripts {
		if i >= 9 {
			break // Only show first 9 with numbers
		}
		num := i + 1
		selected := m.scriptList.Index() == i
		label := script.Name
		isDir := script.Extension == ".dir"
		if script.Extension == ".dir" {
			icon := script.Icon
			if icon == "" {
				icon = "📂"
			}
			label = fmt.Sprintf("%s %s/", icon, script.Name)
		}

		prefix := fmt.Sprintf("  [%d] ", num)
		var styledLabel string
		if isDir {
			if selected {
				styledLabel = ui.SelectedDirectoryStyle.Render(label)
			} else {
				styledLabel = ui.DirectoryStyle.Render(label)
			}
		} else {
			if selected {
				styledLabel = ui.SelectedExecutableStyle.Render(label)
			} else {
				styledLabel = ui.ExecutableStyle.Render(label)
			}
		}

		if selected {
			result += ui.SelectedStyle.Render(prefix) + styledLabel + "\n"
			if script.Description != "" {
				result += ui.DimStyle.Render(fmt.Sprintf("      %s", script.Description)) + "\n"
			}
		} else {
			result += ui.NormalStyle.Render(prefix) + styledLabel + "\n"
			if script.Description != "" {
				result += ui.DimStyle.Render(fmt.Sprintf("      %s", script.Description)) + "\n"
			}
		}
	}
	return result
}

func (m Model) renderExecutingView() string {
	content := "\n"
	content += ui.TitleStyle.Render("⚡ Ejecutando: "+m.currentScript.Name) + "\n\n"
	content += ui.DimStyle.Render("El script se está ejecutando...") + "\n"
	
	return content
}

func (m Model) renderResultView() string {
	breadcrumb := ui.RenderBreadcrumb([]string{"Inicio", m.currentCategory.Name}, m.rootDir)
	
	content := breadcrumb
	
	if m.executionResult == 0 {
		content += ui.SuccessStyle.Render("✓ Script completado exitosamente") + "\n"
	} else {
		content += ui.ErrorStyle.Render(fmt.Sprintf("✗ El script falló con código: %d", m.executionResult)) + "\n"
		
		// Show error output if available
		if m.executionError != "" {
			content += "\n" + ui.ErrorStyle.Render("Error:") + "\n"
			content += ui.DimStyle.Render(m.executionError) + "\n"
		}
	}
	
	content += "\n" + ui.DimStyle.Render("enter/./0/esc: volver  q: salir")
	
	return content
}

// Helper types for list items
type categoryItem struct {
	category Category
	index    int
}

func (i categoryItem) FilterValue() string { return i.category.Name }
func (i categoryItem) Title() string {
	return fmt.Sprintf("%s  %s", i.category.Icon, i.category.Name)
}
func (i categoryItem) Description() string {
	return fmt.Sprintf("%s (%d script(s))", i.category.Description, i.category.ScriptCount)
}

type scriptItem struct {
	script Script
	index  int
}

func (i scriptItem) FilterValue() string { return i.script.Name }
func (i scriptItem) Title() string       { return i.script.Name }
func (i scriptItem) Description() string { return i.script.Description }

func (m Model) createCategoryList() list.Model {
	items := make([]list.Item, len(m.categories))
	for i, cat := range m.categories {
		items[i] = categoryItem{category: cat, index: i}
	}
	
	l := list.New(items, list.NewDefaultDelegate(), m.width, m.height-15)
	l.Title = ""
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	
	return l
}

func (m Model) createScriptList() list.Model {
	items := make([]list.Item, len(m.scripts))
	for i, script := range m.scripts {
		items[i] = scriptItem{script: script, index: i}
	}
	
	l := list.New(items, list.NewDefaultDelegate(), m.width, m.height-18)
	l.Title = ""
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	
	return l
}

func readLauncherVersion(rootDir string) string {
	versionFile := filepath.Join(rootDir, "VERSION.txt")
	data, err := os.ReadFile(versionFile)
	if err != nil {
		return ""
	}
	line := strings.SplitN(strings.TrimSpace(string(data)), "\n", 2)[0]
	fields := strings.Fields(line)
	if len(fields) == 0 {
		return ""
	}
	return fields[0]
}

func decorateHeaderWithVersion(header, version string) string {
	version = strings.TrimSpace(version)
	if header == "" || version == "" {
		return header
	}

	lines := strings.Split(header, "\n")
	last := -1
	maxWidth := 0
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" {
			last = i
		}
		if w := len([]rune(line)); w > maxWidth {
			maxWidth = w
		}
	}
	if last == -1 {
		return header
	}

	line := lines[last]
	lineWidth := len([]rune(line))
	padding := (maxWidth - lineWidth) + 2
	if padding < 2 {
		padding = 2
	}

	lines[last] = line + strings.Repeat(" ", padding) + ui.ErrorStyle.Render(version)
	return strings.Join(lines, "\n")
}

// Commands

type categoriesLoadedMsg struct {
	categories []Category
}

type scriptsLoadedMsg struct {
	scripts []Script
}

type scriptExecutedMsg struct {
	exitCode int
	errorOutput string
}

type errorMsg struct {
	err error
}

func loadCategories(rootDir string) tea.Cmd {
	return func() tea.Msg {
		cats, err := ScanCategories(rootDir)
		if err != nil {
			return errorMsg{err}
		}
		return categoriesLoadedMsg{categories: cats}
	}
}

func loadScripts(categoryPath string) tea.Cmd {
	return func() tea.Msg {
		scripts, err := ScanScripts(categoryPath)
		if err != nil {
			return errorMsg{err}
		}
		return scriptsLoadedMsg{scripts: scripts}
	}
}

func executeScript(script Script) tea.Cmd {
	return tea.ExecProcess(getScriptCommand(script), func(err error) tea.Msg {
		exitCode := 0
		errorOutput := ""
		
		if err != nil {
			// Try to extract exit code from error
			if exitErr, ok := err.(*exec.ExitError); ok {
				exitCode = exitErr.ExitCode()
			} else {
				exitCode = 1
				errorOutput = err.Error()
			}
		}
		
		return scriptExecutedMsg{exitCode: exitCode, errorOutput: errorOutput}
	})
}

// ListAllScripts prints all scripts organized by category
func ListAllScripts() {
	// Get root directory - try multiple strategies
	var rootDir string
	
	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "scripts")); err == nil {
			rootDir = cwd
		} else if _, err := os.Stat(filepath.Join(cwd, "..", "scripts")); err == nil {
			rootDir, _ = filepath.Abs("..")
		}
	}
	
	if rootDir == "" {
		execPath, _ := os.Executable()
		realPath, _ := filepath.EvalSymlinks(execPath)
		rootDir = filepath.Dir(realPath)
	}

	categories, err := ScanCategories(rootDir)
	if err != nil {
		fmt.Printf("Error scanning categories: %v\n", err)
		return
	}

	staticDir := utils.GetStaticPath(rootDir)
	fmt.Println(ui.LoadASCIIArt(staticDir))
	fmt.Println(ui.RenderBreadcrumb([]string{"Inicio", "Lista completa"}, rootDir))
	
	totalScripts := 0
	for _, cat := range categories {
		fmt.Printf("\n%s %s\n", cat.Icon, ui.TitleStyle.Render(cat.Name))
		fmt.Println(ui.DimStyle.Render(cat.Description))
		fmt.Println()
		
		scripts, _ := ScanScripts(cat.Path)
		for _, script := range scripts {
			fmt.Printf("  • %s\n", script.Name)
			if script.Description != "" {
				fmt.Printf("    %s\n", ui.DimStyle.Render("── "+script.Description))
			}
		}
		
		totalScripts += len(scripts)
	}
	
	fmt.Printf("\n%s\n", ui.DrawSeparator(60))
	fmt.Printf("%s\n", ui.DimStyle.Render(fmt.Sprintf("Total: %d scripts en %d categorías", totalScripts, len(categories))))
}
