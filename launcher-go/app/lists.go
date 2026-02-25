package app

import (
	"fmt"

	"github.com/charmbracelet/bubbles/list"
	"github.com/lucas/launcher/core"
)

// categoryItem wraps core.Category for the BubbleTea list component.
type categoryItem struct {
	category core.Category
	index    int
}

func (i categoryItem) FilterValue() string { return i.category.Name }
func (i categoryItem) Title() string {
	return fmt.Sprintf("%s  %s", i.category.Icon, i.category.Name)
}
func (i categoryItem) Description() string {
	return fmt.Sprintf("%s (%d script(s))", i.category.Description, i.category.ScriptCount)
}

// scriptItem wraps core.Script for the BubbleTea list component.
type scriptItem struct {
	script core.Script
	index  int
}

func (i scriptItem) FilterValue() string { return i.script.Name }
func (i scriptItem) Title() string       { return i.script.Name }
func (i scriptItem) Description() string { return i.script.Description }

// createCategoryList builds a BubbleTea list.Model from the current categories.
func (m Model) createCategoryList() list.Model {
	items := make([]list.Item, len(m.categories))
	for i, cat := range m.categories {
		items[i] = categoryItem{category: cat, index: i}
	}
	l := list.New(items, list.NewDefaultDelegate(), m.width, m.height-15)
	l.Title = ""
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	return l
}

// createScriptList builds a BubbleTea list.Model from the current scripts.
func (m Model) createScriptList() list.Model {
	items := make([]list.Item, len(m.scripts))
	for i, script := range m.scripts {
		items[i] = scriptItem{script: script, index: i}
	}
	l := list.New(items, list.NewDefaultDelegate(), m.width, m.height-18)
	l.Title = ""
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	return l
}
