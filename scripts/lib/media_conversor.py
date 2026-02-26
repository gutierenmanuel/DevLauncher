#!/usr/bin/env python3
"""Conversor multimedia para DevLauncher.

Soporta:
- Video: cambio de formato y extracción de audio
- Audio: cambio de formato
- Imagen: cambio de formato

Modo:
- single: un archivo
- all: todos los archivos de una extensión en carpeta actual

Salida: output_conv/
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


VIDEO_EXTENSIONS = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"}
AUDIO_EXTENSIONS = {".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a"}
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".avif", ".bmp", ".tiff"}


def normalize_extension(value: str) -> str:
    value = value.strip().lower()
    if not value:
        return value
    if not value.startswith("."):
        value = f".{value}"
    return value


def ensure_ffmpeg() -> str:
    ffmpeg_path = shutil.which("ffmpeg")
    if not ffmpeg_path:
        raise RuntimeError("No se encontró ffmpeg en el PATH.")
    return ffmpeg_path


def ensure_pillow():
    try:
        from PIL import Image  # noqa: F401
    except ImportError as exc:
        raise RuntimeError("Falta dependencia Pillow. Instala con: pip install pillow") from exc


def parse_resize(value: str | None) -> tuple[int, int] | None:
    if not value:
        return None

    text = value.lower().replace(" ", "")
    if "x" not in text:
        raise RuntimeError("--resize debe tener formato ANCHOxALTO, por ejemplo 1920x1080")

    width_text, height_text = text.split("x", 1)
    try:
        width = int(width_text)
        height = int(height_text)
    except ValueError as exc:
        raise RuntimeError("--resize debe tener valores numéricos enteros") from exc

    if width <= 0 or height <= 0:
        raise RuntimeError("--resize debe tener valores mayores a 0")

    return (width, height)


def normalize_quality(value: int | None) -> int | None:
    if value is None:
        return None
    if value < 1 or value > 100:
        raise RuntimeError("--quality debe estar entre 1 y 100")
    return value


def validate_extensions(kind: str, operation: str, source_ext: str, target_ext: str) -> None:
    source_sets = {
        "video": VIDEO_EXTENSIONS,
        "audio": AUDIO_EXTENSIONS,
        "image": IMAGE_EXTENSIONS,
    }

    target_sets = {
        "video": VIDEO_EXTENSIONS,
        "audio": AUDIO_EXTENSIONS,
        "image": IMAGE_EXTENSIONS,
    }

    if source_ext not in source_sets[kind]:
        allowed = ", ".join(sorted(source_sets[kind]))
        raise RuntimeError(f"Extensión de origen inválida para {kind}. Permitidas: {allowed}")

    if operation == "extract_audio":
        if target_ext not in AUDIO_EXTENSIONS:
            allowed = ", ".join(sorted(AUDIO_EXTENSIONS))
            raise RuntimeError(f"Extensión de salida inválida para extracción de audio. Permitidas: {allowed}")
    else:
        if target_ext not in target_sets[kind]:
            allowed = ", ".join(sorted(target_sets[kind]))
            raise RuntimeError(f"Extensión de salida inválida para {kind}. Permitidas: {allowed}")


def convert_with_ffmpeg(ffmpeg_path: str, input_file: Path, output_file: Path) -> None:
    command = [ffmpeg_path, "-y", "-i", str(input_file), str(output_file)]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Falló ffmpeg para {input_file.name}: {result.stderr.strip() or result.stdout.strip()}")


def convert_image(
    input_file: Path,
    output_file: Path,
    resize: tuple[int, int] | None,
    quality: int | None,
) -> None:
    ensure_pillow()
    from PIL import Image

    save_format_map = {
        ".jpg": "JPEG",
        ".jpeg": "JPEG",
        ".png": "PNG",
        ".webp": "WEBP",
        ".avif": "AVIF",
        ".bmp": "BMP",
        ".tiff": "TIFF",
    }

    output_ext = output_file.suffix.lower()
    image_format = save_format_map.get(output_ext)
    if not image_format:
        raise RuntimeError(f"Formato de salida de imagen no soportado: {output_ext}")

    with Image.open(input_file) as image:
        if resize:
            image = image.resize(resize, Image.Resampling.LANCZOS)

        if image.mode in {"RGBA", "P"} and image_format == "JPEG":
            image = image.convert("RGB")

        save_kwargs: dict = {}
        if image_format in {"JPEG", "WEBP", "AVIF"} and quality is not None:
            save_kwargs["quality"] = quality

        if image_format == "PNG" and quality is not None:
            compress_level = max(0, min(9, int(round((100 - quality) * 9 / 100))))
            save_kwargs["compress_level"] = compress_level

        image.save(output_file, format=image_format, **save_kwargs)


def resolve_sources(kind: str, workdir: Path, mode: str, input_file: str | None, filter_ext: str | None) -> list[Path]:
    allowed_by_kind = {
        "video": VIDEO_EXTENSIONS,
        "audio": AUDIO_EXTENSIONS,
        "image": IMAGE_EXTENSIONS,
    }

    allowed = allowed_by_kind[kind]

    if mode == "single":
        if not input_file:
            raise RuntimeError("Debes indicar --input en modo single.")
        source = Path(input_file).expanduser().resolve()
        if not source.exists() or not source.is_file():
            raise RuntimeError(f"No existe el archivo: {source}")
        if source.suffix.lower() not in allowed:
            ext_list = ", ".join(sorted(allowed))
            raise RuntimeError(f"Extensión no válida para {kind}. Permitidas: {ext_list}")
        return [source]

    if not filter_ext:
        raise RuntimeError("En modo all debes indicar --filter-ext (ej: .mp4, .wav, .png).")

    normalized_filter = normalize_extension(filter_ext)
    if normalized_filter not in allowed:
        ext_list = ", ".join(sorted(allowed))
        raise RuntimeError(f"Filtro de extensión inválido para {kind}. Permitidas: {ext_list}")

    matches = [
        item
        for item in sorted(workdir.iterdir())
        if item.is_file() and item.suffix.lower() == normalized_filter
    ]

    if not matches:
        raise RuntimeError(f"No se encontraron archivos {normalized_filter} en la carpeta actual.")

    return matches


def run_conversion(
    kind: str,
    operation: str,
    target_ext: str,
    sources: list[Path],
    output_dir: Path,
    resize: tuple[int, int] | None,
    quality: int | None,
) -> list[Path]:
    outputs: list[Path] = []

    ffmpeg_path = None
    if kind in {"video", "audio"} or operation == "extract_audio":
        ffmpeg_path = ensure_ffmpeg()

    for source in sources:
        source_ext = source.suffix.lower()
        validate_extensions(kind, operation, source_ext, target_ext)

        output_file = output_dir / f"{source.stem}_to_{target_ext.lstrip('.')}{target_ext}"

        if kind == "image":
            convert_image(source, output_file, resize=resize, quality=quality)
        else:
            convert_with_ffmpeg(ffmpeg_path, source, output_file)

        outputs.append(output_file)

    return outputs


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Conversor multimedia para DevLauncher")
    parser.add_argument("--kind", required=True, choices=["video", "audio", "image"])
    parser.add_argument("--operation", required=True, choices=["convert", "extract_audio"])
    parser.add_argument("--mode", required=True, choices=["single", "all"])
    parser.add_argument("--workdir", required=True)
    parser.add_argument("--target-ext", required=True)
    parser.add_argument("--input", required=False)
    parser.add_argument("--filter-ext", required=False)
    parser.add_argument("--resize", required=False, help="Formato ANCHOxALTO, solo para imagen")
    parser.add_argument("--quality", required=False, type=int, help="Calidad 1-100, solo para imagen")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    workdir = Path(args.workdir).resolve()
    output_dir = workdir / "output_conv"
    output_dir.mkdir(parents=True, exist_ok=True)

    target_ext = normalize_extension(args.target_ext)
    resize = parse_resize(args.resize)
    quality = normalize_quality(args.quality)

    if args.kind != "video" and args.operation == "extract_audio":
        print("✗ extract_audio solo aplica a kind=video", file=sys.stderr)
        return 1

    try:
        sources = resolve_sources(
            kind=args.kind,
            workdir=workdir,
            mode=args.mode,
            input_file=args.input,
            filter_ext=args.filter_ext,
        )

        outputs = run_conversion(
            kind=args.kind,
            operation=args.operation,
            target_ext=target_ext,
            sources=sources,
            output_dir=output_dir,
            resize=resize if args.kind == "image" else None,
            quality=quality if args.kind == "image" else None,
        )

        print(f"✓ Conversión completada. Archivos generados: {len(outputs)}")
        print(f"Salida: {output_dir}")
        for item in outputs:
            print(f" - {item.name}")
        return 0
    except RuntimeError as error:
        print(f"✗ {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
