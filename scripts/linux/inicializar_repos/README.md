# 🧱 Inicializar Repos (Linux)

Scripts para crear estructuras base de proyectos, organizados por tecnología.

## 📁 Estructura

```
inicializar_repos/
├── go/                          ← Proyectos Go
│   ├── init_go_module.sh        # Módulo Go simple
│   └── init_go_proyect.sh       # Repo Go completo
├── python/                      ← Proyectos Python
│   └── init_python_project.sh   # Python + uv + venv + pytest
├── frontend/                    ← Proyectos Frontend
│   └── init_frontend_project.sh # React + Vite + Tailwind + shadcn
├── wails/                       ← Proyectos Wails (Go + Frontend)
│   └── init_wails_project.sh    # Frontend + Backend + Wails App
├── data/                        ← Proyectos de Datos
│   ├── init_data_python.sh      # Data Science (uv + Jupyter + Pandas)
│   └── init_julia_repo.sh       # Julia (Pluto + Makie + DuckDB)
└── functional_structure.sh      ← Estructura genérica para repos completos
```

## 🚀 Uso

```bash
dl
# → linux → inicializar_repos → [go|python|frontend|wails|data]
```

## 🧪 Tests

Los tests están en `tests/inicializar_repos/`.

```bash
# Ejecutar todos
./tests/inicializar_repos/run_all.sh

# Por categoría
./tests/inicializar_repos/run_all.sh go
./tests/inicializar_repos/run_all.sh data
```

Resultados en `tests/inicializar_repos/<categoria>/output/` para evaluación manual.
