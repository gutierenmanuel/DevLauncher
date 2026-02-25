//go:build darwin

// embed_darwin.go — Embedea únicamente los binarios necesarios para macOS.
//
// Al compilar con GOOS=darwin, Go activa este archivo y excluye embed_linux.go
// y embed_windows.go. El resultado es que el installer macOS solo lleva:
//   - assets/launcher-mac       → el launcher para macOS
//   - assets/scripts/           → scripts de shell
//   - assets/static/            → recursos estáticos (ascii art, etc.)
//   - assets/VERSION.txt        → versión del release
//
// Nota: no se embebe un uninstaller-mac porque aún no existe un binario
// de desinstalación compilado para darwin. Cuando se añada, agregar:
//
//	assets/uninstaller-mac
//
// a la directiva //go:embed de abajo.
//
// Esto reduce el tamaño del installer de ~25 MB a ~10 MB.
package main

import "embed"

//go:embed assets/launcher-mac assets/scripts assets/static assets/VERSION.txt
var assetsFS embed.FS
