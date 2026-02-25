package app

import (
"fmt"
"runtime"
"strings"

"github.com/charmbracelet/lipgloss"
"github.com/lucas/installer/core"
)

func (m Model) View() string {
switch m.phase {
case core.PhaseSplash:
return m.viewSplash()
case core.PhaseDetecting:
return m.viewDetecting()
case core.PhaseConfirm:
return m.viewConfirm()
case core.PhaseInstalling:
return m.viewInstalling()
case core.PhaseShellConfig:
return m.viewShellConfig()
case core.PhaseDesktopShortcut:
return m.viewDesktopShortcut()
case core.PhaseDone:
return m.viewDone()
case core.PhaseError:
return m.viewError()
}
return ""
}

func (m Model) viewSplash() string {
title := TitleStyle.Render("🚀 DevScripts Installer")
ver := ""
if m.embeddedVer != "" {
ver = " " + DimStyle.Render(m.embeddedVer)
}
sub := NormalStyle.Render("Sistema de scripts para desarrollo")
hint := DimStyle.Render("Presiona Enter para comenzar")
inner := title + ver + "\n" + sub + "\n\n" + hint
return m.center(BoxStyle.Render(inner))
}

func (m Model) viewDetecting() string {
var sb strings.Builder
sb.WriteString(TitleStyle.Render("Detectando sistema...") + "\n\n")
sb.WriteString(m.spinner.View() + " Buscando instalación existente...\n")
return m.center(sb.String())
}

func (m Model) viewConfirm() string {
var sb strings.Builder

if m.existing == nil {
sb.WriteString(SuccessStyle.Render("✨ Nueva instalación") + "\n")
sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
if m.embeddedVer != "" {
sb.WriteString(CyanStyle.Render("Versión:    "+m.embeddedVer) + "\n")
}
} else {
cmp := core.CompareVersions(m.embeddedVer, m.existing.Version)
if cmp == 0 {
sb.WriteString(SuccessStyle.Render("✓ Ya tienes la última versión") + "\n")
sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
sb.WriteString(DimStyle.Render("Versión instalada: "+m.existing.Version) + "\n")
} else if cmp > 0 {
sb.WriteString(CyanStyle.Render(fmt.Sprintf("↑ Actualización disponible: %s → %s", m.existing.Version, m.embeddedVer)) + "\n")
sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
} else {
sb.WriteString(TitleStyle.Render(fmt.Sprintf("⚠ Versión incrustada %s < instalada %s", m.embeddedVer, m.existing.Version)) + "\n")
sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
}
}

sb.WriteString("\n")
sb.WriteString(NormalStyle.Render(fmt.Sprintf("Archivos a instalar: %d", m.totalFiles)) + "\n\n")
if m.createShortcut {
sb.WriteString(CyanStyle.Render("Acceso directo escritorio: activado") + DimStyle.Render("  (pulsa d para desactivar)") + "\n\n")
} else {
sb.WriteString(DimStyle.Render("Acceso directo escritorio: desactivado  (pulsa d para activar)") + "\n\n")
}
sb.WriteString(SuccessStyle.Render("[y] Instalar") + "  " + ErrorStyle.Render("[q] Cancelar"))
return m.center(BoxStyle.Render(sb.String()))
}

func (m Model) viewInstalling() string {
var sb strings.Builder
sb.WriteString(TitleStyle.Render("Instalando archivos...") + "\n\n")
sb.WriteString(m.progress.View() + "\n\n")
sb.WriteString(NormalStyle.Render(fmt.Sprintf("%d/%d archivos", m.doneFiles, m.totalFiles)) + "\n")
if m.currentFile != "" {
sb.WriteString(DimStyle.Render("→ "+m.currentFile) + "\n")
}
return m.center(sb.String())
}

func (m Model) viewShellConfig() string {
var sb strings.Builder
sb.WriteString(TitleStyle.Render("Configurando perfiles de shell...") + "\n\n")
sb.WriteString(m.spinner.View() + " Escribiendo configuración...\n")
return m.center(sb.String())
}

func (m Model) viewDesktopShortcut() string {
var sb strings.Builder
sb.WriteString(TitleStyle.Render("Creando acceso directo en escritorio...") + "\n\n")
sb.WriteString(m.spinner.View() + " Generando acceso directo...\n")
return m.center(sb.String())
}

func (m Model) viewDone() string {
sourceCmd := "source ~/.bashrc"
if runtime.GOOS == "windows" {
sourceCmd = ". $PROFILE"
} else if runtime.GOOS == "darwin" {
sourceCmd = "source ~/.zshrc"
}

var sb strings.Builder
sb.WriteString(SuccessStyle.Render("✨ ¡Instalación completada!") + "\n\n")
sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
if m.shellProfile != "" {
sb.WriteString(NormalStyle.Render("Perfiles:   "+m.shellProfile) + "\n")
}
if m.shortcutPath != "" {
sb.WriteString(NormalStyle.Render("Acceso directo: "+m.shortcutPath) + "\n")
}
sb.WriteString("\n")
sb.WriteString(CyanStyle.Render("Para activar, ejecuta:") + "\n")
sb.WriteString(PurpleStyle.Render("  "+sourceCmd) + "\n\n")
sb.WriteString(TitleStyle.Render("Comandos disponibles") + "\n")
sb.WriteString(TitleStyle.Render("  • devlauncher") + DimStyle.Render(" (alias: dl)") + "\n")
sb.WriteString(TitleStyle.Render("  • devscript <nombre_script>") + DimStyle.Render(" (ejecución directa)") + "\n\n")
if m.launchAfterDone {
sb.WriteString(CyanStyle.Render("Pulsa Enter para continuar") + "\n")
sb.WriteString(DimStyle.Render("Al continuar, se iniciará DevLauncher automáticamente."))
} else {
sb.WriteString(DimStyle.Render("Pulsa Enter para salir"))
}
return m.center(BoxStyle.Render(sb.String()))
}

func (m Model) viewError() string {
msg := "Error desconocido"
if m.err != nil {
msg = m.err.Error()
}
inner := ErrorStyle.Render("✗ Error durante la instalación") + "\n\n" +
NormalStyle.Render(msg) + "\n\n" +
DimStyle.Render("Presiona cualquier tecla para salir")
return m.center(BoxStyle.Render(inner))
}

func (m Model) center(s string) string {
if m.width == 0 {
return s
}
return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, s)
}
