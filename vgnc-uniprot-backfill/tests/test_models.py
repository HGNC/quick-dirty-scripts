from dataclasses import FrozenInstanceError

import pytest

from vgnc_uniprot_backfill.models import GeneRecord, ReportRow


def _base_gene_kwargs() -> dict[str, str]:
    return {
        "assigned_id": "VGNC:1",
        "assigned_symbol": "ABC1",
        "assigned_name": "ATP binding cassette 1",
        "status": "Approved",
        "species_display_name": "Gallus gallus",
        "chromosome_display_name": "1",
        "ensembl_gene_id": "ENSGALG00000000001",
    }


def test_gene_record_is_frozen() -> None:
    record = GeneRecord(**_base_gene_kwargs())

    with pytest.raises(FrozenInstanceError):
        record.assigned_symbol = "ABC2"


def test_report_row_defaults_uniprot_fields_to_empty_strings() -> None:
    row = ReportRow(**_base_gene_kwargs())

    assert row.uniprot_accession == ""
    assert row.uniprot_source == ""
