#!/usr/bin/env python3
"""Run a SQL file against the MRR MySQL DB and stream the result to CSV.

Usage:
    python export_sql_to_csv.py                              # uses defaults below
    python export_sql_to_csv.py path/to/query.sql [-o out.csv]   # override

Reads DB credentials from mrr-repository/.env (relative to this script).
"""
from __future__ import annotations

import argparse
import csv
import ssl
import sys
from pathlib import Path

import pymysql
from dotenv import dotenv_values

SCRIPT_DIR = Path(__file__).resolve().parent

# --- Defaults (override via CLI) ----------------------------------------
DEFAULT_SQL_FILE = SCRIPT_DIR / "sql_queries" / "bh_consultant_onboarded.sql"
DEFAULT_CSV_FILE = SCRIPT_DIR / "results" / "bh_consultant_onboarded.csv"
# -----------------------------------------------------------------------

ENV_PATH = SCRIPT_DIR / ".env"
ENV_DIR = ENV_PATH.parent
FETCH_BATCH = 1000


def load_env() -> dict[str, str]:
    if not ENV_PATH.exists():
        sys.exit(f"error: .env not found at {ENV_PATH}")
    env = {k: v for k, v in dotenv_values(ENV_PATH).items() if v is not None}
    required = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_DATABASE_NAME"]
    missing = [k for k in required if not env.get(k)]
    if missing:
        sys.exit(f"error: .env missing required keys: {', '.join(missing)}")
    return env


def build_ssl(env: dict[str, str]) -> dict | None:
    if env.get("DB_SSL", "").strip().lower() != "true":
        return None
    ca_path_raw = env.get("DB_CA_PATH", "").strip()
    if not ca_path_raw:
        return {"ssl": {}}
    ca_path = Path(ca_path_raw)
    if not ca_path.is_absolute():
        ca_path = (ENV_DIR / ca_path).resolve()
    if not ca_path.exists():
        sys.exit(f"error: DB_CA_PATH not found at {ca_path}")
    return {"ca": str(ca_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description="Run SQL and stream to CSV.")
    parser.add_argument(
        "sql_file", nargs="?", type=Path, default=DEFAULT_SQL_FILE,
        help=f"Path to .sql file (default: {DEFAULT_SQL_FILE.name})",
    )
    parser.add_argument(
        "-o", "--output", type=Path, default=None,
        help=f"Output CSV path (default: {DEFAULT_CSV_FILE.name} when SQL is the default, else <sql_basename>.csv)",
    )
    args = parser.parse_args()

    sql_path: Path = args.sql_file.resolve()
    if not sql_path.exists():
        sys.exit(f"error: SQL file not found: {sql_path}")

    if args.output is not None:
        out_path = args.output.resolve()
    elif sql_path == DEFAULT_SQL_FILE.resolve():
        out_path = DEFAULT_CSV_FILE.resolve()
    else:
        out_path = sql_path.with_suffix(".csv")

    sql = sql_path.read_text().strip().rstrip(";")
    env = load_env()
    ssl_opt = build_ssl(env)

    conn_kwargs = dict(
        host=env["DB_HOST"],
        port=int(env["DB_PORT"]),
        user=env["DB_USER"],
        password=env["DB_PASSWORD"],
        database=env["DB_DATABASE_NAME"],
        charset="utf8mb4",
        connect_timeout=10,
        read_timeout=300,
        cursorclass=pymysql.cursors.SSCursor,
    )
    if ssl_opt is not None:
        conn_kwargs["ssl"] = ssl_opt

    print(f"connecting to {env['DB_HOST']}:{env['DB_PORT']}/{env['DB_DATABASE_NAME']} ...")
    conn = pymysql.connect(**conn_kwargs)
    rows_written = 0
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            headers = [d[0] for d in cur.description] if cur.description else []
            if not headers:
                sys.exit("error: query returned no result set")

            with out_path.open("w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow(headers)
                while True:
                    batch = cur.fetchmany(FETCH_BATCH)
                    if not batch:
                        break
                    writer.writerows(batch)
                    rows_written += len(batch)
    finally:
        conn.close()

    print(f"wrote {rows_written} rows to {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
