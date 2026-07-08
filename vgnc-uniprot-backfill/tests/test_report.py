from __future__ import annotations

import csv
from pathlib import Path

from vgnc_uniprot_backfill.models import ReportRow
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


def _row_kwargs(assigned_id: str, ensembl_gene_id: str) -> dict[str, str]:
    return {
        "assigned_id": assigned_id,
        "assigned_symbol": f"SYM{assigned_id[-1]}",
        "assigned_name": f"Gene {assigned_id}",
        "status": "Approved",
        "species_display_name": "Gallus gallus",
        "chromosome_display_name": "1",
        "ensembl_gene_id": ensembl_gene_id,
    }


def test_csv_report_writer_writes_expected_header_and_rows(tmp_path: Path) -> None:
    rows = [
        ReportRow(
            **_row_kwargs("VGNC:1", "ENSGALG00000000001"),
            uniprot_accession="P12345",
            uniprot_source="SWISSPROT",
        ),
        ReportRow(
            **_row_kwargs("VGNC:1", "ENSGALG00000000001"),
            uniprot_accession="Q11111",
            uniprot_source="SPTREMBL",
        ),
        ReportRow(**_row_kwargs("VGNC:2", "ENSGALG00000000002")),
    ]

    out_path = tmp_path / "report.csv"

    writer = CsvReportWriter()
    writer.write(rows, out_path)

    with out_path.open(newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        assert reader.fieldnames == _HEADER
        written_rows = list(reader)

    assert len(written_rows) == 3

    empty_accession_row = next(
        row for row in written_rows if row["assigned_id"] == "VGNC:2"
    )
    assert empty_accession_row["uniprot_accession"] == ""
