package core

import (
	"errors"
	"fmt"
	"path/filepath"
	"sort"
	"strings"
)

// RelOrFull returns a path relative to base when possible, otherwise target.
func RelOrFull(base, target string) string {
	rel, err := filepath.Rel(base, target)
	if err != nil {
		return target
	}
	return rel
}

// ResolveScriptQuery selects one script from allScripts using query.
// Matching order:
//  1) absolute path equality
//  2) exact relative path/suffix match
//  3) exact file name
//  4) partial contains
func ResolveScriptQuery(query, scriptsRoot string, allScripts []Script) (Script, error) {
	normalizedQuery := strings.TrimSpace(query)
	if normalizedQuery == "" {
		return Script{}, errors.New("script query vacía")
	}
	normalizedQuery = strings.ReplaceAll(normalizedQuery, "\\", "/")

	if len(allScripts) == 0 {
		return Script{}, errors.New("no se encontraron scripts")
	}

	if filepath.IsAbs(query) {
		for _, script := range allScripts {
			if strings.EqualFold(filepath.Clean(script.Path), filepath.Clean(query)) {
				return script, nil
			}
		}
	}

	relMatches := make([]Script, 0)
	exactNameMatches := make([]Script, 0)
	containsMatches := make([]Script, 0)
	queryLower := strings.ToLower(normalizedQuery)

	for _, script := range allScripts {
		rel := RelOrFull(scriptsRoot, script.Path)
		rel = strings.ReplaceAll(rel, "\\", "/")
		nameLower := strings.ToLower(script.Name)
		relLower := strings.ToLower(rel)

		if strings.EqualFold(rel, normalizedQuery) || strings.HasSuffix(relLower, "/"+queryLower) {
			relMatches = append(relMatches, script)
			continue
		}
		if nameLower == queryLower {
			exactNameMatches = append(exactNameMatches, script)
			continue
		}
		if strings.Contains(relLower, queryLower) || strings.Contains(nameLower, queryLower) {
			containsMatches = append(containsMatches, script)
		}
	}

	if len(relMatches) == 1 {
		return relMatches[0], nil
	}
	if len(relMatches) > 1 {
		return Script{}, ambiguousQueryError("ruta relativa", relMatches, scriptsRoot)
	}

	if len(exactNameMatches) == 1 {
		return exactNameMatches[0], nil
	}
	if len(exactNameMatches) > 1 {
		return Script{}, ambiguousQueryError("nombre exacto", exactNameMatches, scriptsRoot)
	}

	if len(containsMatches) == 1 {
		return containsMatches[0], nil
	}
	if len(containsMatches) > 1 {
		return Script{}, ambiguousQueryError("coincidencia parcial", containsMatches, scriptsRoot)
	}

	return Script{}, fmt.Errorf("script no encontrado: %s", query)
}

func ambiguousQueryError(matchType string, matches []Script, scriptsRoot string) error {
	rels := make([]string, 0, len(matches))
	for _, match := range matches {
		rels = append(rels, RelOrFull(scriptsRoot, match.Path))
	}
	sort.Strings(rels)
	return fmt.Errorf("consulta ambigua (%s), especifica una ruta más precisa: %s", matchType, strings.Join(rels, ", "))
}
