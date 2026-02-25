package core

// CategoryIcon returns the default emoji icon for a category folder.
// Pure: only string return — no I/O.
func CategoryIcon(category string) string {
	return "📂"
}

// CategoryDescription returns the default description for a category folder.
// Pure: only string return — no I/O.
func CategoryDescription(category string) string {
	return "Carpeta detectada automáticamente"
}
