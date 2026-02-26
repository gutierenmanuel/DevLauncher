// DevLauncher — Consola interactiva TUI para lanzar scripts y comandos propios.
//
// # Arquitectura general
//
// El launcher está dividido en tres capas:
//
//   - core/       Lógica pura: tipos de datos (Script, Category, ViewState),
//                 ordenamiento, gradiente de colores e iconos. Sin I/O.
//
//   - middleware/  Funciones impuras: escaneo del sistema de archivos, lectura
//                 de metadatos desde README, ejecución de scripts y carga de
//                 assets estáticos. Recibe dependencias como parámetros.
//
//   - app/        Orquestación BubbleTea: el Model concentra el estado de la
//                 TUI y delega todo el trabajo a core/ y middleware/. Contiene
//                 también el CommandMode (terminal integrada con ":").
//
// # Flujo de ejecución
//
//  1. [main] Detecta flags de CLI. Sin flags, inicia la TUI interactiva.
//  2. [app.NewModel] Resuelve rootDir, staticDir, scriptsRoot y versión.
//  3. [app.Model.Init] Dispara loadCategories → middleware.ScanCategories.
//  4. [app.Model.Update] Reacciona a eventos de teclado, ratón y mensajes Tea.
//     - CategoryView → ScriptView → ExecutingView → ResultView → ScriptView
//  5. [app.Model.View] Delega el renderizado a las funciones render* de views.go.
//  6. Los scripts se ejecutan mediante middleware.ExecuteScript, que captura
//     stdout+stderr y devuelve el exit code al modelo vía scriptExecutedMsg.
//
// # Modo terminal integrado (":")
//
// Desde cualquier vista, ":" abre el CommandMode. Soporta: cd, ls, mkdir,
// search, list, pwd, clear, exit y autocompletado con Tab.

package main

import (
	"encoding/json"
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/launcher/app"
)

func main() {
	// Modo no-interactivo: flags de línea de comandos.
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "-h", "--help":
			showHelp()
			return
		case "-l", "--list":
			// Imprime todas las categorías y scripts en stdout, sin TUI.
			app.ListAllScripts()
			return
		case "--menu-json":
			payload, err := app.BuildMenuJSONBytes(true)
			if err != nil {
				fmt.Printf("Error al generar menú JSON: %v\n", err)
				os.Exit(1)
			}
			fmt.Println(string(payload))
			return
		case "--run":
			if len(os.Args) < 3 {
				fmt.Println("Uso: launcher --run <script|relpath|abspath> [--cwd <ruta>] [--json] [-- arg1 arg2 ...]")
				os.Exit(1)
			}

			scriptQuery := os.Args[2]
			workingDir := ""
			jsonOutput := false
			scriptArgs := make([]string, 0)

			for i := 3; i < len(os.Args); i++ {
				arg := os.Args[i]
				if arg == "--" {
					scriptArgs = append(scriptArgs, os.Args[i+1:]...)
					break
				}

				switch arg {
				case "--json":
					jsonOutput = true
				case "--cwd":
					if i+1 >= len(os.Args) {
						fmt.Println("Falta valor para --cwd")
						os.Exit(1)
					}
					workingDir = os.Args[i+1]
					i++
				default:
					scriptArgs = append(scriptArgs, arg)
				}
			}

			result, err := app.RunScriptByQuery(scriptQuery, workingDir, scriptArgs)
			if err != nil {
				if jsonOutput {
					errOut, _ := json.Marshal(map[string]string{"error": err.Error()})
					fmt.Println(string(errOut))
				} else {
					fmt.Printf("Error: %v\n", err)
				}
				os.Exit(1)
			}

			if jsonOutput {
				payload, marshalErr := json.MarshalIndent(result, "", "  ")
				if marshalErr != nil {
					fmt.Printf("Error serializando resultado JSON: %v\n", marshalErr)
					os.Exit(1)
				}
				fmt.Println(string(payload))
			} else {
				fmt.Printf("Script: %s\n", result.ScriptName)
				fmt.Printf("Ruta: %s\n", result.Path)
				fmt.Printf("WorkingDir: %s\n", result.WorkingDir)
				fmt.Printf("ExitCode: %d\n", result.ExitCode)
				fmt.Println("--- Output ---")
				fmt.Print(result.Output)
			}

			if result.ExitCode != 0 {
				os.Exit(result.ExitCode)
			}
			return
		default:
			fmt.Printf("Opción desconocida: %s\n", os.Args[1])
			fmt.Println("Usa --help para ver las opciones disponibles.")
			os.Exit(1)
		}
	}

	// Modo interactivo: inicia la TUI en pantalla alternativa.
	// WithAltScreen      → usa el buffer alternativo del terminal (sin ensuciar el historial).
	// WithMouseAllMotion → habilita scroll con el ratón pero permite seleccionar texto.
	model := app.NewModel()
	p := tea.NewProgram(&model, tea.WithAltScreen(), tea.WithMouseAllMotion())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error al iniciar el launcher: %v\n", err)
		os.Exit(1)
	}
}

func showHelp() {
	fmt.Println("DevLauncher — Consola interactiva de scripts")
	fmt.Println()
	fmt.Println("Uso: launcher [opción]")
	fmt.Println()
	fmt.Println("Opciones:")
	fmt.Println("  (sin opciones)   Abre el menú interactivo jerárquico")
	fmt.Println("  -l, --list       Lista todos los scripts organizados por categoría")
	fmt.Println("  --menu-json      Exporta el árbol de menús en JSON (con descripciones)")
	fmt.Println("  --run <script>   Ejecuta script por nombre/ruta sin abrir TUI")
	fmt.Println("    --cwd <ruta>   Define directorio de trabajo para --run")
	fmt.Println("    --json         Devuelve resultado de --run en JSON")
	fmt.Println("  -h, --help       Muestra esta ayuda")
	fmt.Println()
	fmt.Println("Navegación en la TUI:")
	fmt.Println("  1. Selecciona una categoría (carpetas de scripts/linux/ o scripts/win/)")
	fmt.Println("  2. Selecciona un script dentro de la categoría")
	fmt.Println("  3. El script se ejecuta y el resultado se muestra en pantalla")
	fmt.Println()
	fmt.Println("Controles:")
	fmt.Println("  ↑/↓  j/k         Navegar")
	fmt.Println("  1-9              Selección rápida por número")
	fmt.Println("  Enter            Abrir / ejecutar")
	fmt.Println("  .  0  Esc        Volver al nivel anterior")
	fmt.Println("  :                Abrir terminal de comandos integrada")
	fmt.Println("  q  Ctrl+C        Salir")
	fmt.Println()
	fmt.Println("Terminal integrada (:):")
	fmt.Println("  cd <ruta>        Cambiar directorio de trabajo para los scripts")
	fmt.Println("  ls  pwd  mkdir   Explorar el sistema de archivos")
	fmt.Println("  search <texto>   Buscar scripts por nombre o descripción")
	fmt.Println("  Tab              Autocompletar comandos y rutas")
	fmt.Println()
}
