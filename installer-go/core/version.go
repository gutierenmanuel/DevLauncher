package core

import (
	"strconv"
	"strings"
)

// ParseVersion extracts the version tag (e.g. "v1.4.0") from the first word of the first line.
func ParseVersion(content string) string {
	line := strings.SplitN(strings.TrimSpace(content), "\n", 2)[0]
	word := strings.Fields(line)
	if len(word) == 0 {
		return ""
	}
	return word[0]
}

// CompareVersions compares semver strings like "v1.4.0". Returns -1, 0, or 1.
func CompareVersions(a, b string) int {
	pa := parseParts(a)
	pb := parseParts(b)
	for i := 0; i < 3; i++ {
		if pa[i] < pb[i] {
			return -1
		}
		if pa[i] > pb[i] {
			return 1
		}
	}
	return 0
}

func parseParts(v string) [3]int {
	v = strings.TrimPrefix(v, "v")
	parts := strings.SplitN(v, ".", 3)
	var nums [3]int
	for i, p := range parts {
		if i >= 3 {
			break
		}
		n, _ := strconv.Atoi(p)
		nums[i] = n
	}
	return nums
}
