from __future__ import annotations

import csv
import logging
from pathlib import Path

from vgnc_uniprot_backfill.ensembl import UniprotLookupResult, UniprotXref
from vgnc_uniprot_backfill.models import GeneRecord
from vgnc_uniprot_backfill.pipeline import run_backfill
from vgnc_uniprot_backfill.report import CsvReportWriter

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


class _StubRepository:
    def list_candidates(self, taxon_id: int | None = None) -> list[GeneRecord]:
        assert taxon_id == 9031
        return [
            GeneRecord(
                assigned_id="VGNC:1",
                assigned_symbol="A",
                assigned_name="Gene A",
                status="Approved",
                species_display_name="Gallus gallus",
                chromosome_display_name="1",
                ensembl_gene_id="ENSG1",
            ),
            GeneRecord(
                assigned_id="VGNC:2",
                assigned_symbol="B",
                assigned_name="Gene B",
                status="Approved",
                species_display_name="Gallus gallus",
                chromosome_display_name="2",
                ensembl_gene_id="ENSG2",
            ),
            GeneRecord(
                assigned_id="VGNC:3",
                assigned_symbol="C",
                assigned_name="Gene C",
                status="Approved",
                species_display_name="Gallus gallus",
                chromosome_display_name="3",
                ensembl_gene_id="ENSG1",
            ),
        ]


class _StubEnsemblClient:
    def __init__(self) -> None:
        self.calls: list[str] = []

    def lookup_uniprot_xrefs(self, ensembl_gene_id: str) -> UniprotLookupResult:
        self.calls.append(ensembl_gene_id)

        if ensembl_gene_id == "ENSG1":
            return UniprotLookupResult(
                xrefs=[
                    UniprotXref(accession="P12345", source="SWISSPROT"),
                    UniprotXref(accession="Q11111", source="SPTREMBL"),
                ],
                failed=False,
            )

        return UniprotLookupResult(xrefs=[], failed=True)


def test_run_backfill_writes_expected_csv_and_logs_failure_tally(
    tmp_path: Path,
    caplog,
) -> None:
    out_path = tmp_path / "out.csv"
    logger = logging.getLogger("vgnc_uniprot_backfill.test")
    client = _StubEnsemblClient()

    with caplog.at_level(logging.INFO, logger=logger.name):
        result = run_backfill(
            out_path=out_path,
            taxon_id=9031,
            repository=_StubRepository(),
            ensembl_client=client,
            report_writer=CsvReportWriter(),
            logger=logger,
        )

    with out_path.open(newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        assert reader.fieldnames == _HEADER
        rows = list(reader)

    assert len(rows) == 5
    assert [row["assigned_id"] for row in rows] == [
        "VGNC:1",
        "VGNC:1",
        "VGNC:2",
        "VGNC:3",
        "VGNC:3",
    ]
    assert client.calls == ["ENSG1", "ENSG2"]
    assert result.lookup_failures == 1
    assert "Ensembl lookup failures: 1" in caplog.text
