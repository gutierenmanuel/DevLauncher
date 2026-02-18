package models

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/lucas/launcher/ui"
)

// CommandMode adds a mini terminal for custom commands
type CommandMode struct {
	active bool
	input  textinput.Model
	output string
}

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
	}
}

// HandleCommand processes a command
func (c *CommandMode) HandleCommand(cmd string, m *Model) tea.Cmd {
	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		c.output = ""
		return nil
	}

	switch parts[0] {
	case "help", "h":
		c.output = ui.SuccessStyle.Render("Comandos disponibles:") + "\n" +
			"  help, h          - Mostrar esta ayuda\n" +
			"  list, ls         - Listar categorías/scripts\n" +
			"  search <texto>   - Buscar scripts\n" +
			"  clear            - Limpiar pantalla\n" +
			"  exit, quit, q    - Salir del launcher\n" +
			"  :1, :2, :3...    - Ir directamente al item N"

	case "list", "ls":
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
				return executeScript(m.currentScript)
			} else {
				c.output = ui.ErrorStyle.Render(fmt.Sprintf("Item %d no existe", num+1))
			}
		} else {
			c.output = ui.ErrorStyle.Render(fmt.Sprintf("Comando desconocido: %s\nEscribe 'help' para ver comandos", parts[0]))
		}
	}

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
		result += "\n" + c.output + "\n"
	}
	
	result += "\n" + ui.DimStyle.Render("esc: cerrar terminal")
	
	return result
}
