package models

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/lucas/launcher/ui"
)

// CommandMode adds a mini terminal for custom commands
type CommandMode struct {
	active bool
	input  textinput.Model
	output string
	viewport viewport.Model
}

var commandSuggestions = []string{"help", "h", "list", "ls", "pwd", "cd", "search", "clear", "exit", "quit", "q"}

// NewCommandMode creates a new command mode
func NewCommandMode() CommandMode {
	ti := textinput.New()
	ti.Placeholder = "comando (help para ayuda)"
	ti.CharLimit = 100
	ti.Width = 50
	
	return CommandMode{
		active: false,
		input:  ti,
		output: "",
		viewport: viewport.New(80, 10),
	}
}

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

func (c *CommandMode) AutoComplete(m *Model) {
	value := c.input.Value()
	trimmed := strings.TrimSpace(value)
	if trimmed == "" || strings.HasPrefix(trimmed, ":") {
		return
	}

	if !strings.Contains(trimmed, " ") {
		prefix := trimmed
		matches := make([]string, 0)
		for _, cmd := range commandSuggestions {
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
		lcp := longestCommonPrefix(matches)
		if len(lcp) > len(prefix) {
			c.input.SetValue(lcp)
			return
		}
		c.output = "Sugerencias:\n  " + strings.Join(matches, "\n  ")
		c.syncViewport()
		return
	}

	cmd, argRaw, ok := splitCommandAndArg(value)
	if !ok || (cmd != "cd" && cmd != "ls") {
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
	if strings.HasSuffix(probe, string(filepath.Separator)) || strings.HasSuffix(probe, "/") || strings.HasSuffix(probe, "\\") {
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
	matches := make([]candidate, 0)
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
		lcp := longestCommonPrefix(names)
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
		rel, relErr := filepath.Rel(m.runDir, completedFull)
		if relErr == nil {
			completedArg = rel
		}
	}

	c.input.SetValue(cmd + " " + completedArg)
}

func splitCommandAndArg(value string) (string, string, bool) {
	trimmed := strings.TrimSpace(value)
	idx := strings.Index(trimmed, " ")
	if idx == -1 {
		return "", "", false
	}
	cmd := strings.TrimSpace(trimmed[:idx])
	arg := strings.TrimSpace(trimmed[idx+1:])
	if cmd == "" {
		return "", "", false
	}
	return cmd, arg, true
}

func longestCommonPrefix(items []string) string {
	if len(items) == 0 {
		return ""
	}
	prefix := items[0]
	for _, item := range items[1:] {
		for !strings.HasPrefix(item, prefix) {
			if prefix == "" {
				return ""
			}
			prefix = prefix[:len(prefix)-1]
		}
	}
	return prefix
}

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

// HandleCommand processes a command
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
			"  search <texto>   - Buscar scripts\n" +
			"  clear            - Limpiar pantalla\n" +
			"  exit, quit, q    - Salir del launcher\n" +
			"  :1, :2, :3...    - Ir directamente al item N"

	case "list":
		if m.state == CategoryView {
			c.output = fmt.Sprintf("Categorías: %d\n", len(m.categories))
			for i, cat := range m.categories {
				c.output += fmt.Sprintf("  [%d] %s %s (%d scripts)\n", i+1, cat.Icon, cat.Name, cat.ScriptCount)
			}
		} else if m.state == ScriptView {
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
			return nil
		}
		info, err := os.Stat(resolved)
		if err != nil || !info.IsDir() {
			c.output = ui.ErrorStyle.Render("Directorio no encontrado")
			return nil
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
			c.output = ui.ErrorStyle.Render("No se pudo listar: "+err.Error())
			return nil
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

	case "search":
		if len(parts) < 2 {
			c.output = ui.ErrorStyle.Render("Uso: search <texto>")
		} else {
			query := strings.ToLower(strings.Join(parts[1:], " "))
			c.output = fmt.Sprintf("Buscando: %s\n", query)
			
			if m.state == CategoryView {
				for i, cat := range m.categories {
					if strings.Contains(strings.ToLower(cat.Name), query) ||
						strings.Contains(strings.ToLower(cat.Description), query) {
						c.output += fmt.Sprintf("  [%d] %s %s\n", i+1, cat.Icon, cat.Name)
					}
				}
			} else if m.state == ScriptView {
				for i, script := range m.scripts {
					if strings.Contains(strings.ToLower(script.Name), query) ||
						strings.Contains(strings.ToLower(script.Description), query) {
						c.output += fmt.Sprintf("  [%d] %s\n", i+1, script.Name)
					}
				}
			}
		}

	case "clear":
		c.output = ""

	case "exit", "quit", "q":
		return tea.Quit

	default:
		// Check for :N syntax (go to item N)
		if strings.HasPrefix(parts[0], ":") {
			numStr := strings.TrimPrefix(parts[0], ":")
			var num int
			fmt.Sscanf(numStr, "%d", &num)
			num-- // Convert to 0-based index
			
			if m.state == CategoryView && num >= 0 && num < len(m.categories) {
				m.currentCategory = m.categories[num]
				m.state = ScriptView
				c.active = false
				return loadScripts(m.currentCategory.Path)
			} else if m.state == ScriptView && num >= 0 && num < len(m.scripts) {
				m.currentScript = m.scripts[num]
				m.state = ExecutingView
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

// View renders the command mode
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
