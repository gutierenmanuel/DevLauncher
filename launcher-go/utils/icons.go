package utils

// CategoryIcon returns the emoji icon for a category
func CategoryIcon(category string) string {
	icons := map[string]string{
		"build":              "🏗️",
		"dev":                "💻",
		"inicializar_repos":  "🆕",
		"instaladores":       "📦",
		"utils":              "🔧",
		"utilidades":         "🔧",
		"gestion_linux":      "⚙️",
		"gestion_windows":    "🪟",
		"iniciar_sistema":    "🚀",
	}
	
	if icon, ok := icons[category]; ok {
		return icon
	}
	return "📁"
}

// CategoryDescription returns the description for a category
func CategoryDescription(category string) string {
	descriptions := map[string]string{
		"build":              "Scripts de compilación y construcción",
		"dev":                "Scripts de desarrollo y servidor",
		"inicializar_repos":  "Inicializadores de proyectos nuevos",
		"instaladores":       "Instaladores de herramientas y dependencias",
		"utils":              "Utilidades y herramientas varias",
		"utilidades":         "Utilidades y herramientas varias",
		"gestion_linux":      "Gestión del sistema Linux",
		"gestion_windows":    "Gestión del sistema Windows",
		"iniciar_sistema":    "Scripts de inicio del sistema",
	}
	
	if desc, ok := descriptions[category]; ok {
		return desc
	}
	return "Scripts varios"
}
