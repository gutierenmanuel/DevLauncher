package app

import (
	"encoding/json"
	"errors"
	"runtime"
	"strings"
	"time"

	"github.com/lucas/launcher/core"
	"github.com/lucas/launcher/middleware"
)

type MenuOption struct {
	Name        string       `json:"name"`
	Description string       `json:"description,omitempty"`
	Type        string       `json:"type"`
	Path        string       `json:"path"`
	RelPath     string       `json:"relPath"`
	Extension   string       `json:"extension,omitempty"`
	Icon        string       `json:"icon,omitempty"`
	DirCount    int          `json:"dirCount,omitempty"`
	ScriptCount int          `json:"scriptCount,omitempty"`
	Options     []MenuOption `json:"options,omitempty"`
}

type MenuCategoryJSON struct {
	Name        string       `json:"name"`
	Description string       `json:"description,omitempty"`
	Icon        string       `json:"icon,omitempty"`
	Path        string       `json:"path"`
	RelPath     string       `json:"relPath"`
	DirCount    int          `json:"dirCount,omitempty"`
	ScriptCount int          `json:"scriptCount,omitempty"`
	Options     []MenuOption `json:"options"`
}

type MenuJSONResponse struct {
	GeneratedAt     string             `json:"generatedAt"`
	Platform        string             `json:"platform"`
	RootDir         string             `json:"rootDir"`
	ScriptsRoot     string             `json:"scriptsRoot"`
	TotalCategories int                `json:"totalCategories"`
	TotalScripts    int                `json:"totalScripts"`
	Categories      []MenuCategoryJSON `json:"categories"`
}

type ScriptRunResult struct {
	Query      string   `json:"query"`
	ScriptName string   `json:"scriptName"`
	Path       string   `json:"path"`
	RelPath    string   `json:"relPath"`
	WorkingDir string   `json:"workingDir"`
	Args       []string `json:"args,omitempty"`
	ExitCode   int      `json:"exitCode"`
	Output     string   `json:"output"`
}

func BuildMenuJSON() (MenuJSONResponse, error) {
	rootDir, err := findRootDir()
	if err != nil {
		return MenuJSONResponse{}, err
	}

	scriptsRoot := middleware.GetScriptsPath(rootDir)
	categories, err := middleware.ScanCategories(rootDir)
	if err != nil {
		return MenuJSONResponse{}, err
	}

	response := MenuJSONResponse{
		GeneratedAt: time.Now().Format(time.RFC3339),
		Platform:    runtime.GOOS,
		RootDir:     rootDir,
		ScriptsRoot: scriptsRoot,
		Categories:  make([]MenuCategoryJSON, 0, len(categories)),
	}

	totalScripts := 0
	for _, category := range categories {
		options, scriptCount, err := buildMenuOptionsRecursive(category.Path, scriptsRoot)
		if err != nil {
			return MenuJSONResponse{}, err
		}
		totalScripts += scriptCount

		response.Categories = append(response.Categories, MenuCategoryJSON{
			Name:        category.Name,
			Description: category.Description,
			Icon:        category.Icon,
			Path:        category.Path,
			RelPath:     core.RelOrFull(scriptsRoot, category.Path),
			DirCount:    category.DirCount,
			ScriptCount: category.ScriptCount,
			Options:     options,
		})
	}

	response.TotalCategories = len(response.Categories)
	response.TotalScripts = totalScripts
	return response, nil
}

func BuildMenuJSONBytes(pretty bool) ([]byte, error) {
	menu, err := BuildMenuJSON()
	if err != nil {
		return nil, err
	}
	if pretty {
		return json.MarshalIndent(menu, "", "  ")
	}
	return json.Marshal(menu)
}

func RunScriptByQuery(query, workingDir string, args []string) (ScriptRunResult, error) {
	if strings.TrimSpace(query) == "" {
		return ScriptRunResult{}, errors.New("script query vacía")
	}

	rootDir, err := findRootDir()
	if err != nil {
		return ScriptRunResult{}, err
	}

	scriptsRoot := middleware.GetScriptsPath(rootDir)
	allScripts, err := collectAllScripts(rootDir)
	if err != nil {
		return ScriptRunResult{}, err
	}

	target, err := core.ResolveScriptQuery(query, scriptsRoot, allScripts)
	if err != nil {
		return ScriptRunResult{}, err
	}

	runDir := strings.TrimSpace(workingDir)
	if runDir == "" {
		runDir = rootDir
	}

	exitCode, output := middleware.ExecuteScriptWithArgs(target, runDir, args)
	return ScriptRunResult{
		Query:      query,
		ScriptName: target.Name,
		Path:       target.Path,
		RelPath:    core.RelOrFull(rootDir, target.Path),
		WorkingDir: runDir,
		Args:       args,
		ExitCode:   exitCode,
		Output:     output,
	}, nil
}

func buildMenuOptionsRecursive(dirPath, scriptsRoot string) ([]MenuOption, int, error) {
	items, err := middleware.ScanScripts(dirPath)
	if err != nil {
		return nil, 0, err
	}

	options := make([]MenuOption, 0, len(items))
	totalScripts := 0

	for _, item := range items {
		if item.Extension == ".dir" {
			children, nestedCount, err := buildMenuOptionsRecursive(item.Path, scriptsRoot)
			if err != nil {
				return nil, 0, err
			}
			totalScripts += nestedCount
			options = append(options, MenuOption{
				Name:        item.Name,
				Description: item.Description,
				Type:        "directory",
				Path:        item.Path,
				RelPath:     core.RelOrFull(scriptsRoot, item.Path),
				Extension:   item.Extension,
				Icon:        item.Icon,
				DirCount:    item.DirCount,
				ScriptCount: item.ScriptCount,
				Options:     children,
			})
			continue
		}

		totalScripts++
		options = append(options, MenuOption{
			Name:        item.Name,
			Description: item.Description,
			Type:        "script",
			Path:        item.Path,
			RelPath:     core.RelOrFull(scriptsRoot, item.Path),
			Extension:   item.Extension,
		})
	}

	return options, totalScripts, nil
}

func collectAllScripts(rootDir string) ([]core.Script, error) {
	categories, err := middleware.ScanCategories(rootDir)
	if err != nil {
		return nil, err
	}

	all := make([]core.Script, 0)
	for _, category := range categories {
		collected, err := collectScriptsRecursive(category.Path)
		if err != nil {
			return nil, err
		}
		all = append(all, collected...)
	}
	return all, nil
}

func collectScriptsRecursive(dirPath string) ([]core.Script, error) {
	items, err := middleware.ScanScripts(dirPath)
	if err != nil {
		return nil, err
	}

	collected := make([]core.Script, 0)
	for _, item := range items {
		if item.Extension == ".dir" {
			nested, err := collectScriptsRecursive(item.Path)
			if err != nil {
				return nil, err
			}
			collected = append(collected, nested...)
			continue
		}
		collected = append(collected, item)
	}
	return collected, nil
}
