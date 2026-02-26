# 🧱 Inicializar Repos (Windows)

Scripts para crear estructuras base de proyectos en Windows con PowerShell.

## 📁 Estructura

```
inicializar_repos/
├── go/                          ← Proyectos Go
│   ├── init_go_module.ps1       # Módulo Go simple
│   └── init_go_project.ps1      # Repo Go completo
├── python/                      ← Proyectos Python
│   └── init_python_project.ps1  # Python + venv
├── frontend/                    ← Proyectos Frontend
│   └── init_frontend_project.ps1
├── wails/                       ← Proyectos Wails (Go + Frontend)
│   └── init_wails_project.ps1
├── data/                        ← Proyectos de Datos
│   ├── init_data_python.ps1
│   └── init_julia_repo.ps1
└── functional_structure.ps1     ← Estructura genérica para repos completos
```

## 🚀 Uso

```powershell
dl
# → win → inicializar_repos → [go|python|frontend|wails|data]
```
