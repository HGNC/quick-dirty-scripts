from __future__ import annotations

import logging

from sqlalchemy import case, func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, aliased, selectinload
from vgnc_orm import (
    DatabaseError,
    DatabaseResource,
    Genefam,
    GeneHasLocation,
    GeneHasXrefs,
    GeneLocation,
    GeneStatus,
    Xref,
    get_readonly_session,
    initialize_engine,
)

from vgnc_uniprot_backfill.models import GeneRecord

_ENSEMBL_GENE_DB_NAME = "ensembl_gene"
_UNIPROT_DB_NAME = "uniprot_protein"
_APPROVED_STATUS_DISPLAY = "Approved"
_ENSEMBL_ASSEMBLY_SOURCE = "Ensembl"
_ENSEMBL_XREF_STATUS_CURRENT = "current"
_ENSEMBL_XREF_STATUS_EXTERNAL_REVIEWED = "externalreviewed"
_ENSEMBL_XREF_STATUS_EXTERNAL_UNREVIEWED = "externalunreviewed"
_VALID_ENSEMBL_XREF_STATUSES = (
    _ENSEMBL_XREF_STATUS_CURRENT,
    _ENSEMBL_XREF_STATUS_EXTERNAL_REVIEWED,
    _ENSEMBL_XREF_STATUS_EXTERNAL_UNREVIEWED,
)


class VgncCandidateRepository:
    def __init__(self, *, logger: logging.Logger | None = None) -> None:
        self._logger = logger or logging.getLogger(__name__)

    def list_candidates(self, taxon_id: int | None = None) -> list[GeneRecord]:
        try:
            initialize_engine()
            with get_readonly_session() as session:
                return self._list_candidates(session, taxon_id=taxon_id)
        except (DatabaseError, SQLAlchemyError) as exc:
            raise RuntimeError("Failed to query candidate genes from vgnc_public") from exc

    def _list_candidates(self, session: Session, taxon_id: int | None) -> list[GeneRecord]:
        ensembl_gene_has_xrefs = aliased(GeneHasXrefs)
        ensembl_xref = aliased(Xref)
        ensembl_database_resource = aliased(DatabaseResource)

        uniprot_gene_has_xrefs = aliased(GeneHasXrefs)
        uniprot_xref = aliased(Xref)
        uniprot_database_resource = aliased(DatabaseResource)

        normalized_ensembl_status = func.lower(ensembl_xref.status)
        ensembl_status_priority = case(
            (normalized_ensembl_status == _ENSEMBL_XREF_STATUS_CURRENT, 0),
            (normalized_ensembl_status == _ENSEMBL_XREF_STATUS_EXTERNAL_REVIEWED, 1),
            (normalized_ensembl_status == _ENSEMBL_XREF_STATUS_EXTERNAL_UNREVIEWED, 2),
            else_=3,
        )

        ranked_ensembl_xref_subquery = (
            select(
                ensembl_gene_has_xrefs.genefam_id.label("genefam_id"),
                ensembl_xref.xref.label("ensembl_gene_id"),
                func.row_number()
                .over(
                    partition_by=ensembl_gene_has_xrefs.genefam_id,
                    order_by=(ensembl_status_priority, ensembl_xref.xref),
                )
                .label("xref_rank"),
            )
            .select_from(ensembl_gene_has_xrefs)
            .join(ensembl_xref, ensembl_xref.id == ensembl_gene_has_xrefs.xref_id)
            .join(
                ensembl_database_resource,
                ensembl_database_resource.id == ensembl_xref.external_db_id,
            )
            .where(
                ensembl_database_resource.db_name == _ENSEMBL_GENE_DB_NAME,
                normalized_ensembl_status.in_(_VALID_ENSEMBL_XREF_STATUSES),
            )
            .subquery()
        )

        ensembl_xref_subquery = (
            select(
                ranked_ensembl_xref_subquery.c.genefam_id,
                ranked_ensembl_xref_subquery.c.ensembl_gene_id,
            )
            .where(ranked_ensembl_xref_subquery.c.xref_rank == 1)
            .subquery()
        )

        uniprot_exists = (
            select(1)
            .select_from(uniprot_gene_has_xrefs)
            .join(uniprot_xref, uniprot_xref.id == uniprot_gene_has_xrefs.xref_id)
            .join(
                uniprot_database_resource,
                uniprot_database_resource.id == uniprot_xref.external_db_id,
            )
            .where(
                uniprot_gene_has_xrefs.genefam_id == Genefam.genefam_id,
                uniprot_database_resource.db_name == _UNIPROT_DB_NAME,
            )
            .exists()
        )

        stmt = (
            select(
                Genefam,
                GeneStatus.display.label("status_display"),
                ensembl_xref_subquery.c.ensembl_gene_id,
            )
            .join(GeneStatus, GeneStatus.id == Genefam.status_id)
            .outerjoin(
                ensembl_xref_subquery,
                ensembl_xref_subquery.c.genefam_id == Genefam.genefam_id,
            )
            .where(
                GeneStatus.display == _APPROVED_STATUS_DISPLAY,
                ~uniprot_exists,
            )
            .options(
                selectinload(Genefam.species),
                selectinload(Genefam.locations)
                .joinedload(GeneHasLocation.location)
                .joinedload(GeneLocation.chromosome),
                selectinload(Genefam.locations).joinedload(GeneHasLocation.assembly),
            )
            .order_by(Genefam.assigned_id)
        )

        if taxon_id is not None:
            stmt = stmt.where(Genefam.taxon_id == taxon_id)

        rows = session.execute(stmt).all()

        candidates: list[GeneRecord] = []
        for gene, status_display, ensembl_gene_id in rows:
            if not ensembl_gene_id:
                self._logger.warning(
                    "Missing valid Ensembl xref in vgnc_public for genefam: "
                    "assigned_id=%s assigned_symbol=%s species_display_name=%s",
                    gene.assigned_id,
                    gene.assigned_symbol or "",
                    gene.species.display_name,
                )
                continue

            candidates.append(
                GeneRecord(
                    assigned_id=gene.assigned_id,
                    assigned_symbol=gene.assigned_symbol or "",
                    assigned_name=gene.assigned_name or "",
                    status=status_display,
                    species_display_name=gene.species.display_name,
                    chromosome_display_name=_select_chromosome_display_name(gene.locations),
                    ensembl_gene_id=ensembl_gene_id,
                )
            )

        return candidates


def _select_chromosome_display_name(locations: list[GeneHasLocation]) -> str:
    if not locations:
        return ""

    sorted_locations = sorted(
        locations,
        key=lambda location: (location.assembly_id, location.location_id, location.source),
    )

    preferred_locations = [
        location
        for location in sorted_locations
        if location.assembly is not None
        and location.assembly.is_vgnc_default
        and location.assembly.source == _ENSEMBL_ASSEMBLY_SOURCE
    ]
    selected_location = preferred_locations[0] if preferred_locations else sorted_locations[0]

    if selected_location.location is None or selected_location.location.chromosome is None:
        return ""

    return selected_location.location.chromosome.display_name
