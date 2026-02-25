package ui

import (
"strings"
)

// RenderFallbackHeader renders a minimal box header when no ASCII art is available.
func RenderFallbackHeader() string {
var result strings.Builder
width := 58
topLine := BoxStyle.Render(BoxTL + strings.Repeat(BoxH, width) + BoxTR)
midLine := BoxStyle.Render(BoxV) + "  🚀 Lanzador Universal de Scripts" + strings.Repeat(" ", width-34) + BoxStyle.Render(BoxV)
botLine := BoxStyle.Render(BoxBL + strings.Repeat(BoxH, width) + BoxBR)
result.WriteString(topLine + "\n")
result.WriteString(midLine + "\n")
result.WriteString(botLine + "\n")
result.WriteString("\n")
return result.String()
}

// RenderBreadcrumb renders the navigation breadcrumb with the current rootDir.
func RenderBreadcrumb(items []string, rootDir string) string {
var result strings.Builder
result.WriteString(DimStyle.Render("📂 "+rootDir) + "\n")
if len(items) == 0 {
return result.String()
}
result.WriteString(BreadcrumbStyle.Render("┌─ "+strings.Join(items, " > ")) + "\n")
return result.String()
}
