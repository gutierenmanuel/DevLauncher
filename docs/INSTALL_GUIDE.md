# 📦 Guía de Instalación - DevLauncher v1.4.0

## 🚀 Instalación Rápida

### Linux / macOS

```bash
cd ~/DataProyects/Scripts_dev
./outputs/installer-linux
source ~/.bashrc  # o ~/.zshrc si usas zsh
```

### Windows (PowerShell)

```powershell
cd ~\DataProyects\Scripts_dev
.\outputs\installer.exe
. $PROFILE
```

---

## ✨ Qué hace el instalador ejecutable

1. Instala DevLauncher en `~/.devscripts`.
2. Configura shell/perfil automáticamente (`.bashrc`, `.zshrc` o `$PROFILE.CurrentUserAllHosts`).
3. Agrega comandos globales:
   - `devlauncher` / `dl`
   - `devscript <nombre>`
4. Permite reinstalación/actualización sin borrar tus scripts de origen.

---

## 🎮 Uso después de instalar

```bash
dl
devlauncher
devscript control_procesos.sh
```

En Windows:

```powershell
dl
devscript init_frontend_project.ps1
```

---

## 🔄 Reinstalación / Actualización

```bash
# Linux/macOS
./outputs/installer-linux

# Windows
.\outputs\installer.exe
```

El instalador detecta una instalación previa y reemplaza el bloque de configuración automáticamente.

---

## 🛠️ Estructura esperada (binarios)

```text
Scripts_dev/
├── outputs/
│   ├── installer-linux
│   ├── installer.exe
│   ├── uninstaller-linux
│   ├── uninstaller.exe
│   ├── launcher-linux
│   ├── launcher.exe
│   └── launcher-mac
├── launcher-go/
├── installer-go/
├── scripts/
└── static/
```

---

## 🧪 Verificar instalación

```bash
echo $DEVSCRIPTS_ROOT      # Linux/macOS
dl
devscript
```

```powershell
echo $env:DEVSCRIPTS_ROOT  # Windows
dl
devscript
```

---

## ❌ Desinstalación

### Linux / macOS (desinstalación)

```bash
./outputs/uninstaller-linux
source ~/.bashrc  # o ~/.zshrc
```

### Windows

```powershell
.\outputs\uninstaller.exe
. $PROFILE
```

---

## 🔧 Troubleshooting

### `command not found: dl`

Recarga el shell:

```bash
source ~/.bashrc  # o ~/.zshrc
```

```powershell
. $PROFILE
```

### `Permission denied` al ejecutar binarios

```bash
chmod +x outputs/installer-linux outputs/uninstaller-linux outputs/launcher-linux outputs/launcher-mac
```

### Windows: `execution of scripts is disabled`

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
