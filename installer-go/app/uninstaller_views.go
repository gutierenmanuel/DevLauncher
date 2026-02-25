package app

import (
"fmt"
"runtime"
"strings"

"github.com/charmbracelet/lipgloss"
"github.com/lucas/installer/core"
)

func (m UninstallModel) View() string {
switch m.phase {
case core.UninstallPhaseSplash:
return m.ucenter(m.viewUSplash())
case core.UninstallPhaseDetecting:
return m.ucenter(m.viewUDetecting())
case core.UninstallPhaseConfirm:
return m.ucenter(m.viewUConfirm())
case core.UninstallPhaseRemoving:
return m.ucenter(m.viewURemoving())
case core.UninstallPhaseShell:
return m.ucenter(m.viewUShell())
case core.UninstallPhaseDone:
return m.ucenter(m.viewUDone())
case core.UninstallPhaseError:
return m.ucenter(m.viewUError())
case core.UninstallPhaseNotFound:
return m.ucenter(m.viewUNotFound())
}
return ""
}

func (m UninstallModel) viewUSplash() string {
title := ErrorStyle.Render("🗑  DevScripts Uninstaller")
sub := NormalStyle.Render("Elimina la instalación de DevScripts")
hint := DimStyle.Render("Presiona Enter para continuar")
return BoxStyle.Render(title + "\n" + sub + "\n\n" + hint)
}

func (m UninstallModel) viewUDetecting() string {
return TitleStyle.Render("Buscando instalación...") + "\n\n" +
m.spinner.View() + " Detectando directorio de instalación...\n"
}

func (m UninstallModel) viewUConfirm() string {
var sb strings.Builder
sb.WriteString(ErrorStyle.Render("⚠  Se eliminará:") + "\n")
sb.WriteString(NormalStyle.Render("  Directorio: "+m.installDir) + "\n")
sb.WriteString(TitleStyle.Render("  Se conserva: scripts/") + DimStyle.Render(" (se renombra a scripts-old-<random>)") + "\n")
sb.WriteString(SuccessStyle.Render("  Tus scripts NO se perderán") + "\n")
if m.existing != nil && m.existing.Version != "" {
sb.WriteString(DimStyle.Render("  Versión:     "+m.existing.Version) + "\n")
}
sb.WriteString("\n")

sb.WriteString(CyanStyle.Render("¿Eliminar también la configuración del shell?") + "\n")
sb.WriteString(DimStyle.Render("  (aliases devlauncher, dl, devscript)") + "\n\n")

optYes := "  [ ] Sí, eliminar configuración del shell"
optNo := "  [ ] No, conservar configuración del shell"
if m.shellCursor == 0 {
optYes = SuccessStyle.Render("  [●] Sí, eliminar configuración del shell")
} else {
optNo = SuccessStyle.Render("  [●] No, conservar configuración del shell")
}
sb.WriteString(optYes + "\n")
sb.WriteString(optNo + "\n\n")
sb.WriteString(DimStyle.Render("↑↓: seleccionar   Enter: confirmar   q: cancelar"))
return BoxStyle.Render(sb.String())
}

func (m UninstallModel) viewURemoving() string {
return TitleStyle.Render("Eliminando instalación...") + "\n\n" +
m.progress.View() + "\n\n" +
DimStyle.Render(m.installDir) + "\n"
}

func (m UninstallModel) viewUShell() string {
return TitleStyle.Render("Limpiando configuración del shell...") + "\n\n" +
m.spinner.View() + " Eliminando bloque DevScripts...\n"
}

func (m UninstallModel) viewUDone() string {
sourceCmd := "source ~/.bashrc"
if runtime.GOOS == "windows" {
sourceCmd = ". $PROFILE"
} else if runtime.GOOS == "darwin" {
sourceCmd = "source ~/.zshrc"
}

var sb strings.Builder
sb.WriteString(SuccessStyle.Render("✓ Desinstalación completada") + "\n\n")
sb.WriteString(NormalStyle.Render("Eliminado: contenido de "+m.installDir) + "\n")
sb.WriteString(TitleStyle.Render("Conservado: scripts-old-<random> (si existía scripts/)") + "\n")
if m.removeShell && m.shellFile != "" {
sb.WriteString(NormalStyle.Render("Perfiles:  "+m.shellFile) + "\n")
sb.WriteString("\n" + CyanStyle.Render("Para aplicar los cambios:") + "\n")
sb.WriteString(PurpleStyle.Render("  "+sourceCmd) + "\n")
}
sb.WriteString("\n" + DimStyle.Render("Presiona cualquier tecla para salir"))
return BoxStyle.Render(sb.String())
}

func (m UninstallModel) viewUError() string {
msg := "Error desconocido"
if m.err != nil {
msg = m.err.Error()
}
return ErrorStyle.Render("✗ Error durante la desinstalación") + "\n\n" +
NormalStyle.Render(msg) + "\n\n" +
DimStyle.Render(fmt.Sprintf("Directorio afectado: %s", m.installDir)) + "\n" +
DimStyle.Render("Presiona cualquier tecla para salir")
}

func (m UninstallModel) viewUNotFound() string {
return BoxStyle.Render(
CyanStyle.Render("ℹ  No se encontró ninguna instalación") + "\n\n" +
NormalStyle.Render("Directorio buscado: "+m.installDir) + "\n\n" +
DimStyle.Render("Presiona cualquier tecla para salir"),
)
}

func (m UninstallModel) ucenter(s string) string {
if m.width == 0 {
return s
}
return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, s)
}
