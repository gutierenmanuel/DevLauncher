#!/usr/bin/env python3
"""Eliminación de fondo para imágenes (simple) usando rembg."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ALLOWED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff"}


def normalize_ext(value: str) -> str:
    value = value.strip().lower()
    if not value:
        return value
    if not value.startswith("."):
        value = f".{value}"
    return value


def ensure_dependencies():
    try:
        from rembg import remove  # noqa: F401
    except ImportError as exc:
        raise RuntimeError("Falta dependencia rembg. Instala con: pip install rembg") from exc


def resolve_sources(workdir: Path, mode: str, input_file: str | None, filter_ext: str | None) -> list[Path]:
    if mode == "single":
        if not input_file:
            raise RuntimeError("Debes indicar --input en modo single.")
        source = Path(input_file).expanduser().resolve()
        if not source.exists() or not source.is_file():
            raise RuntimeError(f"No existe el archivo: {source}")
        if source.suffix.lower() not in ALLOWED_EXTENSIONS:
            allowed = ", ".join(sorted(ALLOWED_EXTENSIONS))
            raise RuntimeError(f"Extensión no válida. Permitidas: {allowed}")
        return [source]

    if not filter_ext:
        raise RuntimeError("En modo all debes indicar --filter-ext (ej: png, jpg, webp).")

    normalized = normalize_ext(filter_ext)
    if normalized not in ALLOWED_EXTENSIONS:
        allowed = ", ".join(sorted(ALLOWED_EXTENSIONS))
        raise RuntimeError(f"Filtro inválido. Permitidas: {allowed}")

    matches = [
        item
        for item in sorted(workdir.iterdir())
        if item.is_file() and item.suffix.lower() == normalized
    ]

    if not matches:
        raise RuntimeError(f"No se encontraron archivos {normalized} en la carpeta actual.")

    return matches


def remove_background(input_file: Path, output_file: Path) -> None:
    from rembg import remove

    input_bytes = input_file.read_bytes()
    output_bytes = remove(input_bytes)
    output_file.write_bytes(output_bytes)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Eliminar fondo de imágenes")
    parser.add_argument("--mode", required=True, choices=["single", "all"])
    parser.add_argument("--workdir", required=True)
    parser.add_argument("--input", required=False)
    parser.add_argument("--filter-ext", required=False)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    workdir = Path(args.workdir).resolve()
    output_dir = workdir / "output_conv"
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        ensure_dependencies()
        sources = resolve_sources(workdir, args.mode, args.input, args.filter_ext)

        outputs = []
        for source in sources:
            output_file = output_dir / f"{source.stem}_no_bg.png"
            remove_background(source, output_file)
            outputs.append(output_file)

        print(f"✓ Fondo eliminado. Archivos generados: {len(outputs)}")
        print(f"Salida: {output_dir}")
        for item in outputs:
            print(f" - {item.name}")
        return 0
    except RuntimeError as error:
        print(f"✗ {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
