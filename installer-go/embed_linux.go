//go:build linux

// embed_linux.go — Embedea únicamente los binarios necesarios para Linux.
//
// Al compilar con GOOS=linux, Go activa este archivo y excluye embed_windows.go
// y embed_darwin.go. El resultado es que el installer Linux solo lleva:
//   - assets/launcher-linux     → el launcher para Linux
//   - assets/uninstaller-linux  → el desinstalador para Linux
//   - assets/scripts/           → scripts de shell
//   - assets/static/            → recursos estáticos (ascii art, etc.)
//   - assets/VERSION.txt        → versión del release
//
// Esto reduce el tamaño del installer de ~25 MB a ~10 MB.
package main

import "embed"

//go:embed assets/launcher-linux assets/uninstaller-linux assets/scripts assets/static assets/VERSION.txt
var assetsFS embed.FS
