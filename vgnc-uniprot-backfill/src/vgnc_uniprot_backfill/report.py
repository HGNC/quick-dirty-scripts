from __future__ import annotations

import csv
from collections.abc import Iterable
from dataclasses import asdict
from pathlib import Path

from vgnc_uniprot_backfill.models import ReportRow

_FIELDNAMES = (
    "assigned_id",
    "assigned_symbol",
    "assigned_name",
    "status",
    "species_display_name",
    "chromosome_display_name",
    "ensembl_gene_id",
    "uniprot_accession",
    "uniprot_source",
)


class CsvReportWriter:
    def write(self, rows: Iterable[ReportRow], out_path: str | Path) -> None:
        output_path = Path(out_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with output_path.open("w", newline="", encoding="utf-8") as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=_FIELDNAMES)
            writer.writeheader()

            for row in rows:
                writer.writerow(asdict(row))
