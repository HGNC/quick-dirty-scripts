from __future__ import annotations

import logging
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Protocol

from vgnc_uniprot_backfill.db import VgncCandidateRepository
from vgnc_uniprot_backfill.ensembl import (
    DEFAULT_MAX_PER_SECOND,
    DEFAULT_USER_AGENT,
    EnsemblXrefClient,
    UniprotLookupResult,
    UniprotXref,
)
from vgnc_uniprot_backfill.models import GeneRecord, ReportRow
from vgnc_uniprot_backfill.report import CsvReportWriter


class CandidateRepository(Protocol):
    def list_candidates(self, taxon_id: int | None = None) -> list[GeneRecord]:
        """Return candidate genes to backfill."""


class EnsemblLookupClient(Protocol):
    def lookup_uniprot_xrefs(self, ensembl_gene_id: str) -> UniprotLookupResult:
        """Lookup UniProt xrefs for one Ensembl gene ID."""


@dataclass(frozen=True)
class PipelineResult:
    candidate_genes: int
    unique_ensembl_ids: int
    report_rows: int
    lookup_failures: int


def run_backfill(
    *,
    out_path: str | Path,
    taxon_id: int | None = None,
    max_per_second: float = DEFAULT_MAX_PER_SECOND,
    user_agent: str = DEFAULT_USER_AGENT,
    repository: CandidateRepository | None = None,
    ensembl_client: EnsemblLookupClient | None = None,
    report_writer: CsvReportWriter | None = None,
    logger: logging.Logger | None = None,
) -> PipelineResult:
    pipeline_logger = logger or logging.getLogger(__name__)
    resolved_repository = repository or VgncCandidateRepository()
    resolved_client = ensembl_client or EnsemblXrefClient(
        max_per_second=max_per_second,
        user_agent=user_agent,
        logger=pipeline_logger,
    )
    resolved_writer = report_writer or CsvReportWriter()

    candidates = sorted(
        resolved_repository.list_candidates(taxon_id=taxon_id),
        key=lambda candidate: candidate.assigned_id,
    )
    ensembl_gene_ids = sorted({candidate.ensembl_gene_id for candidate in candidates})

    lookup_failures = 0
    xrefs_by_ensembl_gene_id: dict[str, list[UniprotXref]] = {}
    for ensembl_gene_id in ensembl_gene_ids:
        lookup_result = resolved_client.lookup_uniprot_xrefs(ensembl_gene_id)
        if lookup_result.failed:
            lookup_failures += 1
        xrefs_by_ensembl_gene_id[ensembl_gene_id] = sorted(
            lookup_result.xrefs,
            key=lambda xref: (xref.accession, xref.source),
        )

    report_rows = _expand_report_rows(candidates, xrefs_by_ensembl_gene_id)
    resolved_writer.write(report_rows, out_path)

    pipeline_logger.info("Ensembl lookup failures: %d", lookup_failures)
    pipeline_logger.info("Wrote %d report rows to %s", len(report_rows), out_path)

    return PipelineResult(
        candidate_genes=len(candidates),
        unique_ensembl_ids=len(ensembl_gene_ids),
        report_rows=len(report_rows),
        lookup_failures=lookup_failures,
    )


def _expand_report_rows(
    candidates: list[GeneRecord],
    xrefs_by_ensembl_gene_id: dict[str, list[UniprotXref]],
) -> list[ReportRow]:
    report_rows: list[ReportRow] = []

    for candidate in candidates:
        candidate_xrefs = xrefs_by_ensembl_gene_id.get(candidate.ensembl_gene_id, [])
        candidate_payload = asdict(candidate)

        if not candidate_xrefs:
            report_rows.append(ReportRow(**candidate_payload))
            continue

        for xref in candidate_xrefs:
            report_rows.append(
                ReportRow(
                    **candidate_payload,
                    uniprot_accession=xref.accession,
                    uniprot_source=xref.source,
                )
            )

    return report_rows
