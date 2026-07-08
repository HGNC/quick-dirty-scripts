from __future__ import annotations

import csv
import os
import subprocess
import sys
from pathlib import Path

import pytest
from dotenv import load_dotenv
from sqlalchemy import text
from vgnc_orm import get_readonly_session, initialize_engine

_REQUIRED_DB_ENV_VARS = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")
_PLACEHOLDER_VALUES = {"your_username", "your_password"}
_RUN_EXTERNAL_ENSEMBL_ENV = "RUN_EXTERNAL_ENSEMBL"
_HEADER = [
    "assigned_id",
    "assigned_symbol",
    "assigned_name",
    "status",
    "species_display_name",
    "chromosome_display_name",
    "ensembl_gene_id",
    "uniprot_accession",
    "uniprot_source",
]


def _require_integration_db_or_skip() -> None:
    project_root = Path(__file__).resolve().parents[1]
    load_dotenv(dotenv_path=project_root / ".env", override=False)

    missing = [
        key
        for key in _REQUIRED_DB_ENV_VARS
        if not os.getenv(key) or os.getenv(key) in _PLACEHOLDER_VALUES
    ]
    if missing:
        pytest.skip(
            f"Integration DB not configured. Missing/placeholder env vars: {', '.join(missing)}"
        )

    try:
        initialize_engine()
        with get_readonly_session() as session:
            session.execute(text("SELECT 1"))
    except Exception as exc:  # pragma: no cover - environment-dependent
        pytest.skip(f"Integration DB unavailable: {exc}")


def _require_external_ensembl_or_skip() -> None:
    if os.getenv(_RUN_EXTERNAL_ENSEMBL_ENV) != "1":
        pytest.skip(
            f"Set {_RUN_EXTERNAL_ENSEMBL_ENV}=1 to run live Ensembl CLI smoke integration test"
        )


def test_cli_smoke_writes_csv_and_logs_failure_tally(tmp_path: Path) -> None:
    _require_external_ensembl_or_skip()
    _require_integration_db_or_skip()

    project_root = Path(__file__).resolve().parents[1]
    out_path = tmp_path / "out.csv"

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "vgnc_uniprot_backfill",
            "--out",
            str(out_path),
            "--taxon-id",
            "9031",
        ],
        cwd=project_root,
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0, result.stdout + result.stderr

    with out_path.open(newline="", encoding="utf-8") as csv_file:
        reader = csv.reader(csv_file)
        header = next(reader)
        rows = list(reader)

    assert header == _HEADER
    assert len(rows) >= 1
    assert "Ensembl lookup failures:" in (result.stdout + result.stderr)
