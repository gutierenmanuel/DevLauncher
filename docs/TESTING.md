# 🧪 Testing Guide - DevScripts

## 📋 Descripción

Suite de tests automatizados para validar que todos los scripts funcionan correctamente sin ejecutarlos.

## 🚀 Ejecutar Tests

### Todos los tests

```bash
cd ~/DataProyects/Scripts_dev
./scripts/linux/tests/run_all_tests.sh
```

### Test individual

```bash
# Test específico para una categoría
bash scripts/linux/tests/test_gestion_linux.sh
bash scripts/linux/tests/test_instaladores.sh
bash scripts/linux/tests/test_inicializar_repos.sh
bash scripts/linux/tests/test_iniciar_sistema.sh
```

## 📊 Qué se testea

### 1. Existencia de archivos
- ✓ Verifica que todos los scripts existen
- ✓ Verifica que tienen permisos de ejecución

### 2. Sintaxis bash
- ✓ Valida sintaxis con `bash -n`
- ✓ Detecta errores de sintaxis antes de ejecutar

### 3. Estructura
- ✓ Verifica que tienen descripción/comentarios
- ✓ Valida formato esperado

## 📂 Estructura de Tests

```
scripts/linux/tests/
├── run_all_tests.sh           → Runner principal
├── test_gestion_linux.sh      → Tests para gestion_linux/
├── test_inicializar_repos.sh  → Tests para inicializar_repos/
├── test_iniciar_sistema.sh    → Tests para iniciar_sistema/
└── test_instaladores.sh       → Tests para instaladores/
```

## ✅ Output de Tests

```
╔════════════════════════════════════════════════════════════╗
║           Test Suite - DevScripts Validation              ║
╚════════════════════════════════════════════════════════════╝

Testing test_gestion_linux... ✓ PASS
Testing test_inicializar_repos... ✓ PASS
Testing test_iniciar_sistema... ✓ PASS
Testing test_instaladores... ✓ PASS

════════════════════════════════════════════════════════════
Total:   4
Passed:  4
Failed:  0
Skipped: 0
════════════════════════════════════════════════════════════
```

## 🔧 Agregar Nuevos Tests

### Crear un test para una nueva categoría

```bash
#!/bin/bash
# Tests para scripts de mi_nueva_categoria

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test 1: Verificar existencia
test_scripts_exist() {
    local scripts=(
        "script1.sh"
        "script2.sh"
    )
    
    for script in "${scripts[@]}"; do
        local path="$SCRIPT_DIR/mi_nueva_categoria/$script"
        [ -f "$path" ] || return 1
        [ -x "$path" ] || return 1
        
        # Verificar sintaxis bash
        bash -n "$path" || return 1
    done
    
    return 0
}

# Ejecutar tests
test_scripts_exist || exit 1

exit 0
```

### Agregar al test runner

El test runner automáticamente detecta archivos `test_*.sh` en el directorio de tests.

## 🎯 Casos de Uso

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Scripts
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: ./scripts/linux/tests/run_all_tests.sh
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running script tests..."
./scripts/linux/tests/run_all_tests.sh

if [ $? -ne 0 ]; then
    echo "Tests failed! Commit aborted."
    exit 1
fi

echo "Tests passed!"
exit 0
```

### Development Workflow

```bash
# 1. Modificar un script
vim scripts/linux/gestion_linux/mi_script.sh

# 2. Ejecutar tests
./scripts/linux/tests/run_all_tests.sh

# 3. Si pasa, commitear
git add .
git commit -m "Update mi_script.sh"
```

## 🛠️ Troubleshooting

### Test falla: "Permission denied"

**Causa:** Script no tiene permisos de ejecución.

**Solución:**
```bash
chmod +x scripts/linux/categoria/script.sh
```

### Test falla: "Syntax error"

**Causa:** Error de sintaxis bash en el script.

**Solución:**
```bash
# Ver el error específico
bash -n scripts/linux/categoria/script.sh

# Corregir el script
vim scripts/linux/categoria/script.sh
```

### Test timeout

**Causa:** Test tomó más de 5 segundos (límite por defecto).

**Solución:**
Verificar si el script tiene loops infinitos o comandos que esperan input.

## 📝 Mejores Prácticas

### 1. Tests no deben modificar el sistema
- Solo validan sintaxis y estructura
- No ejecutan los scripts realmente
- No instalan/desinstalan nada

### 2. Tests deben ser rápidos
- Timeout de 5 segundos por test
- Solo verificaciones básicas
- Sin I/O pesado

### 3. Tests deben ser idempotentes
- Pueden ejecutarse múltiples veces
- Siempre producen el mismo resultado
- No dependen de estado previo

### 4. Tests deben ser independientes
- Cada test es autónomo
- No dependen del orden de ejecución
- Pueden ejecutarse en paralelo

## 🔄 Integración con el Launcher

Los tests pueden ejecutarse desde el launcher:

```bash
dl
# Seleccionar: tests
# Ejecutar: run_all_tests.sh
```

## 📊 Exit Codes

- `0` - Todos los tests pasaron
- `1` - Al menos un test falló
- `124` - Timeout

## 🎨 Colorización

Los tests usan colores ANSI para mejor legibilidad:
- 🟢 Verde: Tests que pasan
- 🔴 Rojo: Tests que fallan
- 🟡 Amarillo: Tests con timeout/skip

## 📈 Estadísticas

El test runner muestra:
- **Total**: Número de tests ejecutados
- **Passed**: Tests exitosos
- **Failed**: Tests fallidos
- **Skipped**: Tests omitidos (timeout)

---

**Versión**: v1.0  
**Última actualización**: 2026-02-18  
**Mantenedor**: DevScripts Team
