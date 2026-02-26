#!/usr/bin/env python3
"""Conversor de datos/tablas para DevLauncher.

Incluye conversiones tabulares, compresión de datos y utilidades dev/infra.
Siempre escribe resultados en output_conv.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import sqlite3
import re
import sys
from configparser import ConfigParser
from pathlib import Path
from typing import Callable


SOURCE_EXTENSIONS = {
    "excel_to_csvs": {".xlsx", ".xlsm", ".xls"},
    "csv_to_excel": {".csv"},
    "json_to_csv": {".json"},
    "csv_to_json": {".csv"},
    "json_to_excel": {".json"},
    "excel_to_json": {".xlsx", ".xlsm", ".xls"},
    "parquet_to_csv": {".parquet"},
    "csv_to_parquet": {".csv"},
    "parquet_to_json": {".parquet"},
    "json_to_parquet": {".json"},
    "parquet_to_excel": {".parquet"},
    "excel_to_parquet": {".xlsx", ".xlsm", ".xls"},
    "xml_to_csv": {".xml"},
    "csv_to_xml": {".csv"},
    "sqlite_to_csv": {".sqlite", ".db", ".sqlite3"},
    "csv_to_sqlite": {".csv"},
    "sqlite_to_excel": {".sqlite", ".db", ".sqlite3"},
    "excel_to_sqlite": {".xlsx", ".xlsm", ".xls"},
    "ods_to_csv": {".ods"},
    "csv_to_ods": {".csv"},
    "ods_to_excel": {".ods"},
    "excel_to_ods": {".xlsx", ".xlsm", ".xls"},
    "yaml_to_json": {".yaml", ".yml"},
    "json_to_yaml": {".json"},
    "yaml_to_csv": {".yaml", ".yml"},
    "csv_to_yaml": {".csv"},
    "csv_to_csv_gz": {".csv"},
    "csv_gz_to_csv": {".csv.gz"},
    "json_to_json_gz": {".json"},
    "json_gz_to_json": {".json.gz"},
    "parquet_to_feather": {".parquet"},
    "feather_to_parquet": {".feather"},
    "json_to_jsonl": {".json"},
    "jsonl_to_json": {".jsonl"},
    "env_to_json": {".env"},
    "json_to_env": {".json"},
    "ini_to_yaml": {".ini"},
    "yaml_to_ini": {".yaml", ".yml"},
    "csv_to_sql_insert": {".csv"},
    "json_to_sql_insert": {".json"},
    "sql_insert_to_csv": {".sql"},
    "sql_insert_to_json": {".sql"},
}


def sanitize_name(value: str) -> str:
    text = value.strip() or "sheet"
    text = re.sub(r"[^a-zA-Z0-9_-]+", "_", text)
    return text.strip("_") or "sheet"


def load_pandas():
    try:
        import pandas as pd
    except ImportError as exc:
        raise RuntimeError(
            "Falta dependencia 'pandas'. Instala con: pip install pandas"
        ) from exc
    return pd


def load_yaml_module():
    try:
        import yaml
    except ImportError as exc:
        raise RuntimeError("Falta dependencia 'pyyaml'. Instala con: pip install pyyaml") from exc
    return yaml


def ensure_optional_dependency(module_name: str, install_hint: str) -> None:
    try:
        __import__(module_name)
    except ImportError as exc:
        raise RuntimeError(f"Falta dependencia '{module_name}'. Instala con: {install_hint}") from exc


def check_dependencies(operation: str) -> None:
    needs_pandas = {
        "excel_to_csvs", "csv_to_excel", "json_to_csv", "csv_to_json", "json_to_excel",
        "excel_to_json", "parquet_to_csv", "csv_to_parquet", "parquet_to_json",
        "json_to_parquet", "parquet_to_excel", "excel_to_parquet", "xml_to_csv",
        "csv_to_xml", "sqlite_to_csv", "csv_to_sqlite", "sqlite_to_excel",
        "excel_to_sqlite", "ods_to_csv", "csv_to_ods", "ods_to_excel", "excel_to_ods",
        "yaml_to_csv", "csv_to_yaml", "parquet_to_feather", "feather_to_parquet",
        "csv_to_sql_insert", "json_to_sql_insert", "sql_insert_to_csv", "sql_insert_to_json",
    }

    if operation in needs_pandas:
        load_pandas()

    if "excel" in operation or "sqlite_to_excel" in operation or "parquet_to_excel" in operation or operation == "csv_to_excel":
        ensure_optional_dependency("openpyxl", "pip install openpyxl")

    if "parquet" in operation or "feather" in operation:
        ensure_optional_dependency("pyarrow", "pip install pyarrow")

    if "ods" in operation:
        ensure_optional_dependency("odf", "pip install odfpy")

    if "yaml" in operation or "ini_to_yaml" in operation:
        load_yaml_module()


def read_json_table(pd, input_file: Path):
    try:
        return pd.read_json(input_file)
    except ValueError:
        return pd.read_json(input_file, lines=True)


def write_json_records(dataframe, output_file: Path) -> None:
    records = dataframe.to_dict(orient="records")
    output_file.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")


def excel_to_csvs(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None)
    outputs = []
    for sheet_name, dataframe in sheets.items():
        safe_sheet = sanitize_name(str(sheet_name))
        output_file = output_dir / f"{input_file.stem}_{safe_sheet}.csv"
        dataframe.to_csv(output_file, index=False)
        outputs.append(output_file)
    return outputs


def csv_to_excel(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.xlsx"
    dataframe.to_excel(output_file, index=False)
    return [output_file]


def json_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = read_json_table(pd, input_file)
    output_file = output_dir / f"{input_file.stem}_from_json.csv"
    dataframe.to_csv(output_file, index=False)
    return [output_file]


def csv_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.json"
    write_json_records(dataframe, output_file)
    return [output_file]


def json_to_excel(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = read_json_table(pd, input_file)
    output_file = output_dir / f"{input_file.stem}_from_json.xlsx"
    dataframe.to_excel(output_file, index=False)
    return [output_file]


def excel_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None)
    outputs = []
    for sheet_name, dataframe in sheets.items():
        safe_sheet = sanitize_name(str(sheet_name))
        output_file = output_dir / f"{input_file.stem}_{safe_sheet}.json"
        write_json_records(dataframe, output_file)
        outputs.append(output_file)
    return outputs


def parquet_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_parquet(input_file)
    output_file = output_dir / f"{input_file.stem}_from_parquet.csv"
    dataframe.to_csv(output_file, index=False)
    return [output_file]


def csv_to_parquet(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.parquet"
    dataframe.to_parquet(output_file, index=False)
    return [output_file]


def parquet_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_parquet(input_file)
    output_file = output_dir / f"{input_file.stem}_from_parquet.json"
    write_json_records(dataframe, output_file)
    return [output_file]


def json_to_parquet(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = read_json_table(pd, input_file)
    output_file = output_dir / f"{input_file.stem}_from_json.parquet"
    dataframe.to_parquet(output_file, index=False)
    return [output_file]


def parquet_to_excel(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_parquet(input_file)
    output_file = output_dir / f"{input_file.stem}_from_parquet.xlsx"
    dataframe.to_excel(output_file, index=False)
    return [output_file]


def excel_to_parquet(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None)
    outputs = []
    for sheet_name, dataframe in sheets.items():
        safe_sheet = sanitize_name(str(sheet_name))
        output_file = output_dir / f"{input_file.stem}_{safe_sheet}.parquet"
        dataframe.to_parquet(output_file, index=False)
        outputs.append(output_file)
    return outputs


def xml_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_xml(input_file)
    output_file = output_dir / f"{input_file.stem}_from_xml.csv"
    dataframe.to_csv(output_file, index=False)
    return [output_file]


def csv_to_xml(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.xml"
    dataframe.to_xml(output_file, index=False, root_name="rows", row_name="row")
    return [output_file]


def get_sqlite_tables(connection: sqlite3.Connection) -> list[str]:
    cursor = connection.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
    return [row[0] for row in cursor.fetchall()]


def sqlite_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    outputs = []
    with sqlite3.connect(input_file) as conn:
        for table in get_sqlite_tables(conn):
            dataframe = pd.read_sql_query(f'SELECT * FROM "{table}"', conn)
            output_file = output_dir / f"{input_file.stem}_{sanitize_name(table)}.csv"
            dataframe.to_csv(output_file, index=False)
            outputs.append(output_file)
    return outputs


def csv_to_sqlite(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    table_name = sanitize_name(input_file.stem)
    output_file = output_dir / f"{input_file.stem}_from_csv.sqlite"
    with sqlite3.connect(output_file) as conn:
        dataframe.to_sql(table_name, conn, if_exists="replace", index=False)
    return [output_file]


def sqlite_to_excel(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    output_file = output_dir / f"{input_file.stem}_from_sqlite.xlsx"
    with sqlite3.connect(input_file) as conn, pd.ExcelWriter(output_file, engine="openpyxl") as writer:
        for table in get_sqlite_tables(conn):
            dataframe = pd.read_sql_query(f'SELECT * FROM "{table}"', conn)
            dataframe.to_excel(writer, index=False, sheet_name=sanitize_name(table)[:31] or "sheet")
    return [output_file]


def excel_to_sqlite(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None)
    output_file = output_dir / f"{input_file.stem}_from_excel.sqlite"
    with sqlite3.connect(output_file) as conn:
        for sheet_name, dataframe in sheets.items():
            table = sanitize_name(str(sheet_name))
            dataframe.to_sql(table, conn, if_exists="replace", index=False)
    return [output_file]


def ods_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None, engine="odf")
    outputs = []
    for sheet_name, dataframe in sheets.items():
        output_file = output_dir / f"{input_file.stem}_{sanitize_name(str(sheet_name))}.csv"
        dataframe.to_csv(output_file, index=False)
        outputs.append(output_file)
    return outputs


def csv_to_ods(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.ods"
    dataframe.to_excel(output_file, index=False, engine="odf")
    return [output_file]


def ods_to_excel(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None, engine="odf")
    output_file = output_dir / f"{input_file.stem}_from_ods.xlsx"
    with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
        for sheet_name, dataframe in sheets.items():
            dataframe.to_excel(writer, index=False, sheet_name=sanitize_name(str(sheet_name))[:31] or "sheet")
    return [output_file]


def excel_to_ods(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    sheets = pd.read_excel(input_file, sheet_name=None)
    output_file = output_dir / f"{input_file.stem}_from_excel.ods"
    with pd.ExcelWriter(output_file, engine="odf") as writer:
        for sheet_name, dataframe in sheets.items():
            dataframe.to_excel(writer, index=False, sheet_name=sanitize_name(str(sheet_name))[:31] or "sheet")
    return [output_file]


def read_yaml_table(input_file: Path):
    yaml = load_yaml_module()
    data = yaml.safe_load(input_file.read_text(encoding="utf-8"))
    if data is None:
        return []
    return data


def yaml_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    data = read_yaml_table(input_file)
    output_file = output_dir / f"{input_file.stem}_from_yaml.json"
    output_file.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return [output_file]


def json_to_yaml(input_file: Path, output_dir: Path) -> list[Path]:
    yaml = load_yaml_module()
    data = json.loads(input_file.read_text(encoding="utf-8"))
    output_file = output_dir / f"{input_file.stem}_from_json.yaml"
    output_file.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False), encoding="utf-8")
    return [output_file]


def yaml_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    data = read_yaml_table(input_file)
    dataframe = pd.DataFrame(data)
    output_file = output_dir / f"{input_file.stem}_from_yaml.csv"
    dataframe.to_csv(output_file, index=False)
    return [output_file]


def csv_to_yaml(input_file: Path, output_dir: Path) -> list[Path]:
    yaml = load_yaml_module()
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.yaml"
    output_file.write_text(yaml.safe_dump(dataframe.to_dict(orient="records"), allow_unicode=True, sort_keys=False), encoding="utf-8")
    return [output_file]


def csv_to_csv_gz(input_file: Path, output_dir: Path) -> list[Path]:
    output_file = output_dir / f"{input_file.name}.gz"
    with input_file.open("rb") as src, gzip.open(output_file, "wb") as dst:
        dst.write(src.read())
    return [output_file]


def csv_gz_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    stem = input_file.name[:-7] if input_file.name.endswith(".csv.gz") else input_file.stem
    output_file = output_dir / f"{stem}_from_gz.csv"
    with gzip.open(input_file, "rb") as src, output_file.open("wb") as dst:
        dst.write(src.read())
    return [output_file]


def json_to_json_gz(input_file: Path, output_dir: Path) -> list[Path]:
    output_file = output_dir / f"{input_file.name}.gz"
    with input_file.open("rb") as src, gzip.open(output_file, "wb") as dst:
        dst.write(src.read())
    return [output_file]


def json_gz_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    stem = input_file.name[:-8] if input_file.name.endswith(".json.gz") else input_file.stem
    output_file = output_dir / f"{stem}_from_gz.json"
    with gzip.open(input_file, "rb") as src, output_file.open("wb") as dst:
        dst.write(src.read())
    return [output_file]


def parquet_to_feather(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_parquet(input_file)
    output_file = output_dir / f"{input_file.stem}_from_parquet.feather"
    dataframe.to_feather(output_file)
    return [output_file]


def feather_to_parquet(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_feather(input_file)
    output_file = output_dir / f"{input_file.stem}_from_feather.parquet"
    dataframe.to_parquet(output_file, index=False)
    return [output_file]


def json_to_jsonl(input_file: Path, output_dir: Path) -> list[Path]:
    data = json.loads(input_file.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        data = [data]
    if not isinstance(data, list):
        raise RuntimeError("El JSON debe ser objeto o lista para convertir a JSONL.")

    output_file = output_dir / f"{input_file.stem}_from_json.jsonl"
    with output_file.open("w", encoding="utf-8") as handle:
        for item in data:
            handle.write(json.dumps(item, ensure_ascii=False) + "\n")
    return [output_file]


def jsonl_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    rows = []
    with input_file.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                rows.append(json.loads(line))

    output_file = output_dir / f"{input_file.stem}_from_jsonl.json"
    output_file.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    return [output_file]


def env_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    data: dict[str, str] = {}
    for line in input_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip()

    output_file = output_dir / f"{input_file.stem}_from_env.json"
    output_file.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return [output_file]


def json_to_env(input_file: Path, output_dir: Path) -> list[Path]:
    data = json.loads(input_file.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise RuntimeError("El JSON para convertir a .env debe ser un objeto clave/valor.")

    output_file = output_dir / f"{input_file.stem}_from_json.env"
    lines = [f"{key}={value}" for key, value in data.items()]
    output_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return [output_file]


def ini_to_yaml(input_file: Path, output_dir: Path) -> list[Path]:
    yaml = load_yaml_module()
    parser = ConfigParser()
    parser.read(input_file, encoding="utf-8")

    data = {section: dict(parser.items(section)) for section in parser.sections()}
    output_file = output_dir / f"{input_file.stem}_from_ini.yaml"
    output_file.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False), encoding="utf-8")
    return [output_file]


def yaml_to_ini(input_file: Path, output_dir: Path) -> list[Path]:
    data = read_yaml_table(input_file)
    if not isinstance(data, dict):
        raise RuntimeError("El YAML para INI debe ser un objeto de secciones.")

    parser = ConfigParser()
    for section, values in data.items():
        parser[str(section)] = {str(k): str(v) for k, v in dict(values).items()}

    output_file = output_dir / f"{input_file.stem}_from_yaml.ini"
    with output_file.open("w", encoding="utf-8") as handle:
        parser.write(handle)
    return [output_file]


def sql_escape(value):
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("'", "''")
    return f"'{text}'"


def dataframe_to_sql_insert(dataframe, table_name: str, output_file: Path) -> None:
    columns = [str(col) for col in dataframe.columns]
    col_sql = ", ".join(f'"{col}"' for col in columns)
    with output_file.open("w", encoding="utf-8") as handle:
        for row in dataframe.to_dict(orient="records"):
            values = ", ".join(sql_escape(row.get(col)) for col in columns)
            handle.write(f"INSERT INTO {sanitize_name(table_name)} ({col_sql}) VALUES ({values});\n")


def csv_to_sql_insert(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = pd.read_csv(input_file)
    output_file = output_dir / f"{input_file.stem}_from_csv.sql"
    dataframe_to_sql_insert(dataframe, input_file.stem, output_file)
    return [output_file]


def json_to_sql_insert(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    dataframe = read_json_table(pd, input_file)
    output_file = output_dir / f"{input_file.stem}_from_json.sql"
    dataframe_to_sql_insert(dataframe, input_file.stem, output_file)
    return [output_file]


def parse_sql_value(token: str):
    token = token.strip()
    if token.upper() == "NULL":
        return None
    if token.startswith("'") and token.endswith("'"):
        return token[1:-1].replace("''", "'")
    try:
        if "." in token:
            return float(token)
        return int(token)
    except ValueError:
        return token


def split_sql_values(values_sql: str) -> list[str]:
    values = []
    current = []
    in_string = False
    i = 0
    while i < len(values_sql):
        char = values_sql[i]
        if char == "'":
            if in_string and i + 1 < len(values_sql) and values_sql[i + 1] == "'":
                current.append("''")
                i += 2
                continue
            in_string = not in_string
            current.append(char)
            i += 1
            continue
        if char == "," and not in_string:
            values.append("".join(current).strip())
            current = []
            i += 1
            continue
        current.append(char)
        i += 1
    if current:
        values.append("".join(current).strip())
    return values


def parse_sql_inserts(input_file: Path) -> dict[str, list[dict]]:
    text = input_file.read_text(encoding="utf-8")
    pattern = re.compile(
        r"INSERT\s+INTO\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*VALUES\s*\((.*?)\);",
        re.IGNORECASE,
    )

    grouped: dict[str, list[dict]] = {}
    for table, columns_sql, values_sql in pattern.findall(text):
        columns = [col.strip().strip('"') for col in columns_sql.split(",")]
        raw_values = split_sql_values(values_sql)
        values = [parse_sql_value(token) for token in raw_values]
        row = dict(zip(columns, values))
        grouped.setdefault(table, []).append(row)
    return grouped


def sql_insert_to_csv(input_file: Path, output_dir: Path) -> list[Path]:
    pd = load_pandas()
    grouped = parse_sql_inserts(input_file)
    if not grouped:
        raise RuntimeError("No se encontraron sentencias INSERT válidas en el archivo SQL.")

    outputs = []
    for table, rows in grouped.items():
        output_file = output_dir / f"{input_file.stem}_{sanitize_name(table)}.csv"
        pd.DataFrame(rows).to_csv(output_file, index=False)
        outputs.append(output_file)
    return outputs


def sql_insert_to_json(input_file: Path, output_dir: Path) -> list[Path]:
    grouped = parse_sql_inserts(input_file)
    if not grouped:
        raise RuntimeError("No se encontraron sentencias INSERT válidas en el archivo SQL.")

    outputs = []
    for table, rows in grouped.items():
        output_file = output_dir / f"{input_file.stem}_{sanitize_name(table)}.json"
        output_file.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
        outputs.append(output_file)
    return outputs


CONVERTERS: dict[str, Callable[[Path, Path], list[Path]]] = {
    "excel_to_csvs": excel_to_csvs,
    "csv_to_excel": csv_to_excel,
    "json_to_csv": json_to_csv,
    "csv_to_json": csv_to_json,
    "json_to_excel": json_to_excel,
    "excel_to_json": excel_to_json,
    "parquet_to_csv": parquet_to_csv,
    "csv_to_parquet": csv_to_parquet,
    "parquet_to_json": parquet_to_json,
    "json_to_parquet": json_to_parquet,
    "parquet_to_excel": parquet_to_excel,
    "excel_to_parquet": excel_to_parquet,
    "xml_to_csv": xml_to_csv,
    "csv_to_xml": csv_to_xml,
    "sqlite_to_csv": sqlite_to_csv,
    "csv_to_sqlite": csv_to_sqlite,
    "sqlite_to_excel": sqlite_to_excel,
    "excel_to_sqlite": excel_to_sqlite,
    "ods_to_csv": ods_to_csv,
    "csv_to_ods": csv_to_ods,
    "ods_to_excel": ods_to_excel,
    "excel_to_ods": excel_to_ods,
    "yaml_to_json": yaml_to_json,
    "json_to_yaml": json_to_yaml,
    "yaml_to_csv": yaml_to_csv,
    "csv_to_yaml": csv_to_yaml,
    "csv_to_csv_gz": csv_to_csv_gz,
    "csv_gz_to_csv": csv_gz_to_csv,
    "json_to_json_gz": json_to_json_gz,
    "json_gz_to_json": json_gz_to_json,
    "parquet_to_feather": parquet_to_feather,
    "feather_to_parquet": feather_to_parquet,
    "json_to_jsonl": json_to_jsonl,
    "jsonl_to_json": jsonl_to_json,
    "env_to_json": env_to_json,
    "json_to_env": json_to_env,
    "ini_to_yaml": ini_to_yaml,
    "yaml_to_ini": yaml_to_ini,
    "csv_to_sql_insert": csv_to_sql_insert,
    "json_to_sql_insert": json_to_sql_insert,
    "sql_insert_to_csv": sql_insert_to_csv,
    "sql_insert_to_json": sql_insert_to_json,
}


def detect_extension(input_path: Path) -> str:
    name = input_path.name.lower()
    if name.endswith(".csv.gz"):
        return ".csv.gz"
    if name.endswith(".json.gz"):
        return ".json.gz"
    return input_path.suffix.lower()


def run_single(operation: str, input_path: Path, output_dir: Path) -> list[Path]:
    if not input_path.exists() or not input_path.is_file():
        raise RuntimeError(f"No existe el archivo: {input_path}")

    expected_ext = SOURCE_EXTENSIONS[operation]
    if detect_extension(input_path) not in expected_ext:
        allowed = ", ".join(sorted(expected_ext))
        raise RuntimeError(f"Extensión no válida para {operation}. Permitidas: {allowed}")

    return CONVERTERS[operation](input_path, output_dir)


def run_all(operation: str, workdir: Path, output_dir: Path) -> list[Path]:
    expected_ext = SOURCE_EXTENSIONS[operation]
    matches = [
        item
        for item in workdir.iterdir()
        if item.is_file() and detect_extension(item) in expected_ext
    ]

    if not matches:
        allowed = ", ".join(sorted(expected_ext))
        raise RuntimeError(
            f"No se encontraron archivos del tipo {allowed} en la carpeta actual."
        )

    outputs: list[Path] = []
    for item in sorted(matches):
        outputs.extend(CONVERTERS[operation](item, output_dir))
    return outputs


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Conversor tabular para DevLauncher")
    parser.add_argument("--operation", required=True, choices=sorted(CONVERTERS.keys()))
    parser.add_argument("--mode", required=True, choices=["single", "all"])
    parser.add_argument("--workdir", required=True)
    parser.add_argument("--input", required=False)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    workdir = Path(args.workdir).resolve()
    output_dir = workdir / "output_conv"
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        check_dependencies(args.operation)

        if args.mode == "single":
            if not args.input:
                raise RuntimeError("Debes indicar --input en modo single.")
            input_path = Path(args.input).expanduser().resolve()
            outputs = run_single(args.operation, input_path, output_dir)
        else:
            outputs = run_all(args.operation, workdir, output_dir)

        print(f"✓ Conversión completada. Archivos generados: {len(outputs)}")
        print(f"Salida: {output_dir}")
        for out in outputs:
            print(f" - {out.name}")
        return 0
    except RuntimeError as error:
        print(f"✗ {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
