package app

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/lucas/launcher/core"
	"github.com/lucas/launcher/middleware"
	"github.com/lucas/launcher/ui"
)

// --- View dispatch ---

func (m *Model) View() string {
	switch m.state {
	case core.CategoryView:
		return m.renderCategoryView()
	case core.ScriptView:
		return m.renderScriptView()
	case core.ExecutingView:
		return m.renderExecutingView()
	case core.ResultView:
		return m.renderResultView()
	}
	return ""
}

// --- Individual views ---

func (m *Model) renderCategoryView() string {
	if m.header == "" && len(m.categories) > 0 {
		m.header = decorateHeaderWithVersion(middleware.LoadASCIIArt(m.staticDir), m.currentVersion)
	}

	header := ""
	if !m.headerShown && len(m.categories) > 0 {
		header = m.header
	}

	breadcrumb := ui.RenderBreadcrumb([]string{"Inicio"}, m.runDir)
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
			break
		}
		num := i + 1
		selected := m.categoryList.Index() == i

		label := fmt.Sprintf("%s %s/", cat.Icon, cat.Name)
		prefix := fmt.Sprintf("  [%d] ", num)
		counts := formatCategoryCounts(cat.DirCount, cat.ScriptCount)

		var styledLabel string
		if selected {
			styledLabel = ui.SelectedDirectoryStyle.Render(label)
		} else {
			styledLabel = ui.DirectoryStyle.Render(label)
		}

		if selected {
			line := ui.SelectedStyle.Render(prefix) + styledLabel
			if counts != "" {
				line += "      " + ui.CountStyle.Render(counts)
			}
			result += line + "\n"
			if strings.TrimSpace(cat.Description) != "" {
				result += ui.DimStyle.Render(fmt.Sprintf("      %s", cat.Description)) + "\n"
			}
		} else {
			line := ui.NormalStyle.Render(prefix) + styledLabel
			if counts != "" {
				line += "      " + ui.CountStyle.Render(counts)
			}
			result += line + "\n"
			if strings.TrimSpace(cat.Description) != "" {
				result += ui.DimStyle.Render(fmt.Sprintf("      %s", cat.Description)) + "\n"
			}
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
	breadcrumb := ui.RenderBreadcrumb(breadcrumbParts, m.runDir)

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
			break
		}
		num := i + 1
		selected := m.scriptList.Index() == i
		isDir := script.Extension == ".dir"

		label := script.Name
		counts := ""
		if isDir {
			icon := script.Icon
			if icon == "" {
				icon = "📂"
			}
			label = fmt.Sprintf("%s %s/", icon, script.Name)
			counts = formatCategoryCounts(script.DirCount, script.ScriptCount)
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
			line := ui.SelectedStyle.Render(prefix) + styledLabel
			if counts != "" {
				line += "      " + ui.CountStyle.Render(counts)
			}
			result += line + "\n"
			if script.Description != "" {
				result += ui.DimStyle.Render(fmt.Sprintf("      %s", script.Description)) + "\n"
			}
		} else {
			line := ui.NormalStyle.Render(prefix) + styledLabel
			if counts != "" {
				line += "      " + ui.CountStyle.Render(counts)
			}
			result += line + "\n"
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
	breadcrumb := ui.RenderBreadcrumb([]string{"Inicio", m.currentCategory.Name}, m.runDir)
	content := breadcrumb

	if m.executionResult == 0 {
		content += ui.SuccessStyle.Render(fmt.Sprintf("✓ Script completado exitosamente (exit code: %d)", m.executionResult)) + "\n"
	} else {
		content += ui.ErrorStyle.Render(fmt.Sprintf("✗ Script falló (exit code: %d)", m.executionResult)) + "\n"
	}
	content += ui.DimStyle.Render("─────────────────────────────────────────────────────────────") + "\n"

	if m.executionOutput != "" {
		content += ui.NormalStyle.Render("Salida del script:") + "\n\n"

		maxWidth := 80
		rawLines := strings.Split(m.executionOutput, "\n")
		var wrappedLines []string

		for _, line := range rawLines {
			if strings.TrimSpace(line) == "" {
				wrappedLines = append(wrappedLines, "")
				continue
			}
			runes := []rune(line)
			for len(runes) > 0 {
				if len(runes) <= maxWidth {
					wrappedLines = append(wrappedLines, string(runes))
					break
				}
				wrappedLines = append(wrappedLines, string(runes[:maxWidth]))
				runes = runes[maxWidth:]
			}
		}

		visibleHeight := m.height - 12
		if visibleHeight < 5 {
			visibleHeight = 5
		}
		maxScroll := len(wrappedLines) - visibleHeight
		if maxScroll < 0 {
			maxScroll = 0
		}
		if m.outputScroll > maxScroll {
			m.outputScroll = maxScroll
		}

		start := m.outputScroll
		end := start + visibleHeight
		if end > len(wrappedLines) {
			end = len(wrappedLines)
		}
		for i := start; i < end; i++ {
			content += wrappedLines[i] + "\n"
		}
		if len(wrappedLines) > visibleHeight {
			scrollInfo := fmt.Sprintf("[Líneas %d-%d de %d]", start+1, end, len(wrappedLines))
			content += "\n" + ui.DimStyle.Render(scrollInfo) + "\n"
		}
	} else {
		content += ui.DimStyle.Render("(Sin salida)") + "\n"
	}

	content += "\n" + ui.DimStyle.Render("↑↓/j/k/scroll: desplazar  enter/./0/esc: volver  q: salir")
	return content
}

// --- Helpers ---

func formatCategoryCounts(dirCount, scriptCount int) string {
	if dirCount <= 0 && scriptCount <= 0 {
		return ""
	}
	if dirCount <= 0 {
		return fmt.Sprintf("%d scripts", scriptCount)
	}
	if scriptCount <= 0 {
		return fmt.Sprintf("%d dirs", dirCount)
	}
	return fmt.Sprintf("%d dirs · %d scripts", dirCount, scriptCount)
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
		if strings.TrimSpace(line) != "" {
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
	lines[last] = line + strings.Repeat(" ", padding) + ui.HeaderVersionStyle.Render(version)
	return strings.Join(lines, "\n")
}

// ListAllScripts prints all scripts organized by category (--list flag).
func ListAllScripts() {
	var rootDir string
	if cwd, err := findRootDir(); err == nil {
		rootDir = cwd
	}

	categories, err := middleware.ScanCategories(rootDir)
	if err != nil {
		fmt.Printf("Error scanning categories: %v\n", err)
		return
	}

	staticDir := middleware.GetStaticPath(rootDir)
	fmt.Println(middleware.LoadASCIIArt(staticDir))
	fmt.Println(ui.RenderBreadcrumb([]string{"Inicio", "Lista completa"}, rootDir))

	totalScripts := 0
	for _, cat := range categories {
		fmt.Printf("\n%s %s\n", cat.Icon, ui.TitleStyle.Render(cat.Name))
		fmt.Println(ui.DimStyle.Render(cat.Description))
		fmt.Println()
		scripts, _ := middleware.ScanScripts(cat.Path)
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
