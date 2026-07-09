from __future__ import annotations

import os
from pathlib import Path

import pytest
from dotenv import load_dotenv
from sqlalchemy import func, select, text
from vgnc_orm import (
    DatabaseResource,
    Genefam,
    GeneHasXrefs,
    Xref,
    get_readonly_session,
    initialize_engine,
)

from vgnc_uniprot_backfill.db import VgncCandidateRepository

_REQUIRED_DB_ENV_VARS = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")
_PLACEHOLDER_VALUES = {"your_username", "your_password"}


def _initialize_db_or_skip() -> None:
    project_env = Path(__file__).resolve().parents[1] / ".env"
    load_dotenv(dotenv_path=project_env, override=False)

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


@pytest.fixture(scope="module", autouse=True)
def _require_integration_db() -> None:
    _initialize_db_or_skip()


def test_list_candidates_returns_rows_with_ensembl_ids() -> None:
    repository = VgncCandidateRepository()

    candidates = repository.list_candidates()

    assert all(candidate.ensembl_gene_id for candidate in candidates)


def test_list_candidates_do_not_have_uniprot_xrefs() -> None:
    repository = VgncCandidateRepository()

    candidates = repository.list_candidates()
    assigned_ids = [candidate.assigned_id for candidate in candidates]

    with get_readonly_session() as session:
        genefam_ids = (
            session.execute(select(Genefam.genefam_id).where(Genefam.assigned_id.in_(assigned_ids)))
            .scalars()
            .all()
        )

        uniprot_hit_count = session.execute(
            select(func.count())
            .select_from(GeneHasXrefs)
            .join(Xref, Xref.id == GeneHasXrefs.xref_id)
            .join(DatabaseResource, DatabaseResource.id == Xref.external_db_id)
            .where(
                GeneHasXrefs.genefam_id.in_(genefam_ids),
                DatabaseResource.db_name == "uniprot_protein",
            )
        ).scalar_one()

    assert uniprot_hit_count == 0
