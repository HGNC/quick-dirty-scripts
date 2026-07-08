from dataclasses import dataclass


@dataclass(frozen=True)
class GeneRecord:
    assigned_id: str
    assigned_symbol: str
    assigned_name: str
    status: str
    species_display_name: str
    chromosome_display_name: str
    ensembl_gene_id: str


@dataclass(frozen=True)
class ReportRow(GeneRecord):
    uniprot_accession: str = ""
    uniprot_source: str = ""
