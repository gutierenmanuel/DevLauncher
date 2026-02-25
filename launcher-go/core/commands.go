package core

import "strings"

// CommandSuggestions is the list of known commands for autocomplete.
var CommandSuggestions = []string{
	"help", "h", "list", "ls", "pwd", "cd", "mkdir", "search", "clear", "exit", "quit", "q",
}

// LongestCommonPrefix returns the longest string that is a prefix of every item.
// Pure: operates only on strings.
func LongestCommonPrefix(items []string) string {
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

// SplitCommandAndArg splits "cmd arg" into its two parts.
// Returns (cmd, arg, ok=false) if no space is found.
// Pure: operates only on strings.
func SplitCommandAndArg(input string) (cmd, arg string, ok bool) {
	trimmed := strings.TrimSpace(input)
	idx := strings.Index(trimmed, " ")
	if idx == -1 {
		return "", "", false
	}
	cmd = strings.TrimSpace(trimmed[:idx])
	arg = strings.TrimSpace(trimmed[idx+1:])
	if cmd == "" {
		return "", "", false
	}
	return cmd, arg, true
}
