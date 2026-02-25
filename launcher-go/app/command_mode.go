package app

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/launcher/core"
	"github.com/lucas/launcher/ui"
)

// CommandMode is the mini terminal overlay in the TUI.
type CommandMode struct {
	active   bool
	input    textinput.Model
	output   string
	viewport viewport.Model
}

// NewCommandMode creates a new CommandMode with default settings.
func NewCommandMode() CommandMode {
	ti := textinput.New()
	ti.Placeholder = "comando (help para ayuda)"
	ti.CharLimit = 100
	ti.Width = 50

	return CommandMode{
		active:   false,
		input:    ti,
		output:   "",
		viewport: viewport.New(80, 10),
	}
}

// SetSize adjusts the viewport to fit the current terminal dimensions.
func (c *CommandMode) SetSize(width, height int) {
	vw := width - 4
	if vw < 20 {
		vw = 20
	}
	vh := height / 3
	if vh < 6 {
		vh = 6
	}
	if vh > 16 {
		vh = 16
	}
	c.viewport.Width = vw
	c.viewport.Height = vh
}

func (c *CommandMode) syncViewport() {
	c.viewport.SetContent(c.output)
	c.viewport.GotoTop()
}

// AutoComplete attempts to autocomplete the current input value.
func (c *CommandMode) AutoComplete(m *Model) {
	value := c.input.Value()
	trimmed := strings.TrimSpace(value)
	if trimmed == "" || strings.HasPrefix(trimmed, ":") {
		return
	}

	if !strings.Contains(trimmed, " ") {
		prefix := trimmed
		matches := make([]string, 0)
		for _, cmd := range core.CommandSuggestions {
			if strings.HasPrefix(cmd, prefix) {
				matches = append(matches, cmd)
			}
		}
		if len(matches) == 0 {
			return
		}
		sort.Strings(matches)
		if len(matches) == 1 {
			c.input.SetValue(matches[0] + " ")
			return
		}
		lcp := core.LongestCommonPrefix(matches)
		if len(lcp) > len(prefix) {
			c.input.SetValue(lcp)
			return
		}
		c.output = "Sugerencias:\n  " + strings.Join(matches, "\n  ")
		c.syncViewport()
		return
	}

	cmd, argRaw, ok := core.SplitCommandAndArg(value)
	if !ok || (cmd != "cd" && cmd != "ls" && cmd != "mkdir") {
		return
	}

	typedArg := strings.TrimSpace(argRaw)
	if typedArg == "" {
		return
	}

	home, _ := os.UserHomeDir()
	expandedArg := typedArg
	if strings.HasPrefix(expandedArg, "~") && home != "" {
		expandedArg = filepath.Join(home, strings.TrimPrefix(expandedArg, "~"))
	}

	isAbs := filepath.IsAbs(expandedArg)
	probe := expandedArg
	if !isAbs {
		probe = filepath.Join(m.runDir, expandedArg)
	}

	searchDir := filepath.Dir(probe)
	prefix := filepath.Base(probe)
	if strings.HasSuffix(probe, string(filepath.Separator)) || strings.HasSuffix(probe, "/") {
		searchDir = probe
		prefix = ""
	}

	entries, err := os.ReadDir(searchDir)
	if err != nil {
		return
	}

	type candidate struct {
		name  string
		isDir bool
	}
	var matches []candidate
	prefixLower := strings.ToLower(prefix)
	for _, entry := range entries {
		name := entry.Name()
		if prefix == "" || strings.HasPrefix(strings.ToLower(name), prefixLower) {
			matches = append(matches, candidate{name: name, isDir: entry.IsDir()})
		}
	}
	if len(matches) == 0 {
		return
	}
	sort.Slice(matches, func(i, j int) bool { return matches[i].name < matches[j].name })

	names := make([]string, 0, len(matches))
	for _, match := range matches {
		names = append(names, match.name)
	}

	selectedName := ""
	selectedDir := false
	if len(matches) == 1 {
		selectedName = matches[0].name
		selectedDir = matches[0].isDir
	} else {
		lcp := core.LongestCommonPrefix(names)
		if len(lcp) <= len(prefix) {
			c.output = "Sugerencias:\n"
			for _, match := range matches {
				marker := "📄"
				if match.isDir {
					marker = "📂"
				}
				c.output += fmt.Sprintf("  %s %s\n", marker, match.name)
			}
			c.syncViewport()
			return
		}
		selectedName = lcp
	}

	completedFull := filepath.Join(searchDir, selectedName)
	if selectedDir {
		completedFull += string(filepath.Separator)
	}

	completedArg := completedFull
	if strings.HasPrefix(typedArg, "~") && home != "" {
		if strings.HasPrefix(completedFull, home) {
			completedArg = "~" + strings.TrimPrefix(completedFull, home)
		}
	} else if !isAbs {
		if rel, relErr := filepath.Rel(m.runDir, completedFull); relErr == nil {
			completedArg = rel
		}
	}

	c.input.SetValue(cmd + " " + completedArg)
}

// HandleMouse scrolls the output viewport on mouse wheel events.
func (c *CommandMode) HandleMouse(msg tea.MouseMsg) tea.Cmd {
	if !c.active || c.output == "" {
		return nil
	}
	switch msg.String() {
	case "wheel up":
		c.viewport.LineUp(3)
	case "wheel down":
		c.viewport.LineDown(3)
	}
	return nil
}

// HandleCommand parses and executes a command string.
func (c *CommandMode) HandleCommand(cmd string, m *Model) tea.Cmd {
	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		c.output = ""
		c.syncViewport()
		return nil
	}

	switch parts[0] {
	case "help", "h":
		c.output = ui.SuccessStyle.Render("Comandos disponibles:") + "\n" +
			"  help, h          - Mostrar esta ayuda\n" +
			"  list, ls         - Listar categorías/scripts\n" +
			"  pwd              - Mostrar directorio actual de ejecución\n" +
			"  cd <ruta>        - Cambiar directorio de ejecución\n" +
			"  ls [ruta]        - Listar archivos y carpetas\n" +
			"  mkdir <nombre>   - Crear directorio\n" +
			"  search <texto>   - Buscar scripts\n" +
			"  clear            - Limpiar pantalla\n" +
			"  exit, quit, q    - Salir del launcher\n" +
			"  :1, :2, :3...    - Ir directamente al item N"

	case "list":
		if m.state == core.CategoryView {
			c.output = fmt.Sprintf("Categorías: %d\n", len(m.categories))
			for i, cat := range m.categories {
				c.output += fmt.Sprintf("  [%d] %s %s (%d scripts)\n", i+1, cat.Icon, cat.Name, cat.ScriptCount)
			}
		} else if m.state == core.ScriptView {
			c.output = fmt.Sprintf("Scripts en %s: %d\n", m.currentCategory.Name, len(m.scripts))
			for i, script := range m.scripts {
				c.output += fmt.Sprintf("  [%d] %s\n", i+1, script.Name)
			}
		}

	case "pwd":
		c.output = fmt.Sprintf("Directorio actual: %s", m.runDir)

	case "cd":
		target := ""
		if len(parts) < 2 {
			target = m.launchDir
		} else {
			target = strings.Join(parts[1:], " ")
			if strings.TrimSpace(target) == "~" {
				home, _ := os.UserHomeDir()
				target = home
			}
			if !filepath.IsAbs(target) {
				target = filepath.Join(m.runDir, target)
			}
		}
		resolved, err := filepath.Abs(target)
		if err != nil {
			c.output = ui.ErrorStyle.Render("Ruta inválida")
			break
		}
		info, err := os.Stat(resolved)
		if err != nil || !info.IsDir() {
			c.output = ui.ErrorStyle.Render("Directorio no encontrado")
			break
		}
		m.runDir = resolved
		c.output = ui.SuccessStyle.Render("Directorio cambiado:") + "\n  " + resolved

	case "ls":
		listPath := m.runDir
		if len(parts) > 1 {
			candidate := strings.Join(parts[1:], " ")
			if !filepath.IsAbs(candidate) {
				candidate = filepath.Join(m.runDir, candidate)
			}
			if resolved, err := filepath.Abs(candidate); err == nil {
				listPath = resolved
			}
		}
		entries, err := os.ReadDir(listPath)
		if err != nil {
			c.output = ui.ErrorStyle.Render("No se pudo listar: " + err.Error())
			break
		}
		names := make([]string, 0, len(entries))
		for _, entry := range entries {
			name := entry.Name()
			if entry.IsDir() {
				name = "📂 " + name + "/"
			} else {
				name = "📄 " + name
			}
			names = append(names, name)
		}
		sort.Strings(names)
		c.output = fmt.Sprintf("Contenido: %s\n", listPath)
		if len(names) == 0 {
			c.output += "  (vacío)"
		} else {
			for _, name := range names {
				c.output += "  " + name + "\n"
			}
		}

	case "mkdir":
		if len(parts) < 2 {
			c.output = ui.ErrorStyle.Render("Uso: mkdir <nombre>")
			break
		}
		dirName := strings.Join(parts[1:], " ")
		targetPath := dirName
		if !filepath.IsAbs(dirName) {
			targetPath = filepath.Join(m.runDir, dirName)
		}
		if err := os.MkdirAll(targetPath, 0755); err != nil {
			c.output = ui.ErrorStyle.Render("Error al crear directorio: " + err.Error())
			break
		}
		c.output = ui.SuccessStyle.Render("✓ Directorio creado:") + "\n  " + targetPath

	case "search":
		if len(parts) < 2 {
			c.output = ui.ErrorStyle.Render("Uso: search <texto>")
			break
		}
		query := strings.ToLower(strings.Join(parts[1:], " "))
		c.output = fmt.Sprintf("Buscando: %s\n", query)
		if m.state == core.CategoryView {
			for i, cat := range m.categories {
				if strings.Contains(strings.ToLower(cat.Name), query) ||
					strings.Contains(strings.ToLower(cat.Description), query) {
					c.output += fmt.Sprintf("  [%d] %s %s\n", i+1, cat.Icon, cat.Name)
				}
			}
		} else if m.state == core.ScriptView {
			for i, script := range m.scripts {
				if strings.Contains(strings.ToLower(script.Name), query) ||
					strings.Contains(strings.ToLower(script.Description), query) {
					c.output += fmt.Sprintf("  [%d] %s\n", i+1, script.Name)
				}
			}
		}

	case "clear":
		c.output = ""

	case "exit", "quit", "q":
		c.syncViewport()
		return tea.Quit

	default:
		if strings.HasPrefix(parts[0], ":") {
			numStr := strings.TrimPrefix(parts[0], ":")
			var num int
			fmt.Sscanf(numStr, "%d", &num)
			num-- // Convert to 0-based index
			if m.state == core.CategoryView && num >= 0 && num < len(m.categories) {
				m.currentCategory = m.categories[num]
				m.currentPath = m.currentCategory.Path
				m.state = core.ScriptView
				m.headerShown = true
				c.active = false
				return loadScripts(m.currentCategory.Path)
			} else if m.state == core.ScriptView && num >= 0 && num < len(m.scripts) {
				m.currentScript = m.scripts[num]
				m.state = core.ExecutingView
				c.active = false
				return executeScript(m.currentScript, m.runDir)
			} else {
				c.output = ui.ErrorStyle.Render(fmt.Sprintf("Item %d no existe", num+1))
			}
		} else {
			c.output = ui.ErrorStyle.Render(fmt.Sprintf("Comando desconocido: %s\nEscribe 'help' para ver comandos", parts[0]))
		}
	}

	c.syncViewport()
	return nil
}

// View renders the command mode overlay.
func (c *CommandMode) View() string {
	if !c.active {
		return ""
	}
	result := "\n" + ui.DimStyle.Render("─────────────────────────────────────────────────────────") + "\n"
	result += ui.TitleStyle.Render("● Terminal de Comandos") + "\n"
	result += c.input.View() + "\n"
	if c.output != "" {
		result += "\n" + c.viewport.View() + "\n"
	}
	result += "\n" + ui.DimStyle.Render("tab: autocompletar  esc: cerrar terminal  rueda: scroll salida")
	return result
}
