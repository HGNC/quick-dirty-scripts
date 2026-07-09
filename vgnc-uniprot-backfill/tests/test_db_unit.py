from __future__ import annotations

import logging
from types import SimpleNamespace

from sqlalchemy.dialects import sqlite

from vgnc_uniprot_backfill.db import VgncCandidateRepository


class _StubResult:
    def __init__(self, rows: list[tuple[object, str, str | None]]) -> None:
        self._rows = rows

    def all(self) -> list[tuple[object, str, str | None]]:
        return self._rows


class _CaptureSession:
    def __init__(self, rows: list[tuple[object, str, str | None]]) -> None:
        self._rows = rows
        self.statement = None

    def execute(self, statement):
        self.statement = statement
        return _StubResult(self._rows)


def _build_gene(*, assigned_id: str, assigned_symbol: str, species_display_name: str) -> object:
    return SimpleNamespace(
        assigned_id=assigned_id,
        assigned_symbol=assigned_symbol,
        assigned_name=f"Name for {assigned_symbol}",
        species=SimpleNamespace(display_name=species_display_name),
        locations=[],
    )


def test_list_candidates_uses_status_priority_to_select_one_ensembl_xref_in_sql() -> None:
    session = _CaptureSession(rows=[])

    repository = VgncCandidateRepository()
    repository._list_candidates(session=session, taxon_id=None)

    assert session.statement is not None
    compiled_sql = str(
        session.statement.compile(
            dialect=sqlite.dialect(),
            compile_kwargs={"literal_binds": True},
        )
    ).lower()

    assert "row_number() over" in compiled_sql
    assert "partition by" in compiled_sql
    assert "case when" in compiled_sql
    assert "then 0" in compiled_sql
    assert "then 1" in compiled_sql
    assert "then 2" in compiled_sql
    assert "current" in compiled_sql
    assert "externalreviewed" in compiled_sql
    assert "externalunreviewed" in compiled_sql
    assert "retired" not in compiled_sql
    assert "inactive" not in compiled_sql


def test_list_candidates_warns_and_skips_genes_without_valid_ensembl_xref(caplog) -> None:
    session = _CaptureSession(
        rows=[
            (
                _build_gene(
                    assigned_id="VGNC:1",
                    assigned_symbol="GENE1",
                    species_display_name="Gallus gallus",
                ),
                "Approved",
                "ENSG000001",
            ),
            (
                _build_gene(
                    assigned_id="VGNC:2",
                    assigned_symbol="GENE2",
                    species_display_name="Gallus gallus",
                ),
                "Approved",
                None,
            ),
        ]
    )

    repository = VgncCandidateRepository()

    with caplog.at_level(logging.WARNING, logger="vgnc_uniprot_backfill.db"):
        candidates = repository._list_candidates(session=session, taxon_id=None)

    assert [candidate.assigned_id for candidate in candidates] == ["VGNC:1"]
    assert "No active Ensembl found" in caplog.text
    assert "	for GENE2 VGNC:2 Gallus gallus" in caplog.text
