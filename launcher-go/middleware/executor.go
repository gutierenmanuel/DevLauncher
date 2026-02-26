package middleware

import (
	"fmt"
	"os/exec"
	"runtime"

	"github.com/lucas/launcher/core"
)

// BuildScriptCommandWithArgs constructs the exec.Cmd to run the given script
// with optional script arguments.
func BuildScriptCommandWithArgs(script core.Script, workingDir string, args []string) *exec.Cmd {
	var cmd *exec.Cmd

	switch script.Extension {
	case ".sh":
		baseArgs := []string{script.Path}
		baseArgs = append(baseArgs, args...)
		cmd = exec.Command("bash", baseArgs...)
	case ".ps1":
		baseArgs := []string{"-ExecutionPolicy", "Bypass", "-File", script.Path}
		baseArgs = append(baseArgs, args...)
		if _, err := exec.LookPath("pwsh"); err == nil {
			cmd = exec.Command("pwsh", baseArgs...)
		} else {
			cmd = exec.Command("powershell", baseArgs...)
		}
	case ".bat":
		baseArgs := []string{"/c", script.Path}
		baseArgs = append(baseArgs, args...)
		cmd = exec.Command("cmd.exe", baseArgs...)
	default:
		cmd = exec.Command("echo", fmt.Sprintf("unsupported script extension: %s", script.Extension))
	}

	if workingDir != "" {
		cmd.Dir = workingDir
	}
	return cmd
}

// BuildScriptCommand constructs the exec.Cmd to run the given script.
// workingDir sets Cmd.Dir; pass "" to use the process default.
func BuildScriptCommand(script core.Script, workingDir string) *exec.Cmd {
	return BuildScriptCommandWithArgs(script, workingDir, nil)
}

// ExecuteScriptWithArgs runs a script with optional args and returns
// (exitCode, combinedOutput). It captures both stdout and stderr.
func ExecuteScriptWithArgs(script core.Script, workingDir string, args []string) (int, string) {
	cmd := BuildScriptCommandWithArgs(script, workingDir, args)
	if cmd == nil {
		return 1, fmt.Sprintf("unsupported script extension: %s", script.Extension)
	}

	if script.Extension != ".sh" && script.Extension != ".ps1" && script.Extension != ".bat" {
		return 1, fmt.Sprintf("unsupported script extension: %s", script.Extension)
	}

	if workingDir != "" && runtime.GOOS != "" {
		// already set in BuildScriptCommandWithArgs
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

// ExecuteScript runs a script and returns (exitCode, combinedOutput).
// It captures both stdout and stderr.
func ExecuteScript(script core.Script, workingDir string) (int, string) {
	return ExecuteScriptWithArgs(script, workingDir, nil)
}
