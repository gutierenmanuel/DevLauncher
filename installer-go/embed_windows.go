//go:build windows

// embed_windows.go — Embedea únicamente los binarios necesarios para Windows.
//
// Al compilar con GOOS=windows, Go activa este archivo y excluye embed_linux.go
// y embed_darwin.go. El resultado es que el installer Windows solo lleva:
//   - assets/launcher.exe       → el launcher para Windows
//   - assets/uninstaller.exe    → el desinstalador para Windows
//   - assets/scripts/           → scripts de PowerShell/shell
//   - assets/static/            → recursos estáticos (ascii art, etc.)
//   - assets/VERSION.txt        → versión del release
//
// Esto reduce el tamaño del installer de ~26 MB a ~10 MB.
package main

import "embed"

//go:embed assets/launcher.exe assets/uninstaller.exe assets/scripts assets/static assets/VERSION.txt
var assetsFS embed.FS
