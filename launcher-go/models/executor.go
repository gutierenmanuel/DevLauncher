package models

import (
	"fmt"
	"os/exec"
	"runtime"
)

// getScriptCommand returns the command to execute a script
func getScriptCommand(script Script, workingDir string) *exec.Cmd {
	var cmd *exec.Cmd

	switch script.Extension {
	case ".sh":
		cmd = exec.Command("bash", script.Path)
	case ".ps1":
		// Try pwsh first, fallback to powershell
		if _, err := exec.LookPath("pwsh"); err == nil {
			cmd = exec.Command("pwsh", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		} else {
			cmd = exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		}
	case ".bat":
		if runtime.GOOS == "windows" {
			cmd = exec.Command("cmd.exe", "/c", script.Path)
		} else {
			cmd = exec.Command("cmd.exe", "/c", script.Path) // WSL scenario
		}
	default:
		// Return a command that will fail with a clear error
		cmd = exec.Command("echo", fmt.Sprintf("unsupported script extension: %s", script.Extension))
	}

	if workingDir != "" {
		cmd.Dir = workingDir
	}

	return cmd
}

// ExecuteScript executes a script and returns the exit code and combined output (stdout+stderr)
func ExecuteScript(script Script, workingDir string) (int, string) {
	var cmd *exec.Cmd

	switch script.Extension {
	case ".sh":
		cmd = exec.Command("bash", script.Path)
	case ".ps1":
		// Try pwsh first, fallback to powershell
		if _, err := exec.LookPath("pwsh"); err == nil {
			cmd = exec.Command("pwsh", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		} else {
			cmd = exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		}
	case ".bat":
		if runtime.GOOS == "windows" {
			cmd = exec.Command("cmd.exe", "/c", script.Path)
		} else {
			cmd = exec.Command("cmd.exe", "/c", script.Path) // WSL scenario
		}
	default:
		return 1, fmt.Sprintf("unsupported script extension: %s", script.Extension)
	}

	if workingDir != "" {
		cmd.Dir = workingDir
	}

	// Capture both stdout and stderr
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
