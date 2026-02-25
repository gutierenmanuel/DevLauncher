package middleware

import (
	"fmt"
	"os/exec"
	"runtime"

	"github.com/lucas/launcher/core"
)

// BuildScriptCommand constructs the exec.Cmd to run the given script.
// workingDir sets Cmd.Dir; pass "" to use the process default.
func BuildScriptCommand(script core.Script, workingDir string) *exec.Cmd {
	var cmd *exec.Cmd

	switch script.Extension {
	case ".sh":
		cmd = exec.Command("bash", script.Path)
	case ".ps1":
		if _, err := exec.LookPath("pwsh"); err == nil {
			cmd = exec.Command("pwsh", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		} else {
			cmd = exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		}
	case ".bat":
		cmd = exec.Command("cmd.exe", "/c", script.Path)
	default:
		cmd = exec.Command("echo", fmt.Sprintf("unsupported script extension: %s", script.Extension))
	}

	if workingDir != "" {
		cmd.Dir = workingDir
	}
	return cmd
}

// ExecuteScript runs a script and returns (exitCode, combinedOutput).
// It captures both stdout and stderr.
func ExecuteScript(script core.Script, workingDir string) (int, string) {
	cmd := BuildScriptCommand(script, workingDir)
	if cmd == nil {
		return 1, fmt.Sprintf("unsupported script extension: %s", script.Extension)
	}

	// For the unsupported-extension echo fallback we need separate handling
	if script.Extension != ".sh" && script.Extension != ".ps1" && script.Extension != ".bat" {
		return 1, fmt.Sprintf("unsupported script extension: %s", script.Extension)
	}

	if workingDir != "" && runtime.GOOS != "" {
		// already set in BuildScriptCommand
	}

	output, err := cmd.CombinedOutput()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = 1
		}
	}
	return exitCode, string(output)
}
