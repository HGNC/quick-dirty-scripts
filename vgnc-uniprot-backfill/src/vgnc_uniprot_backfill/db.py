from __future__ import annotations

from sqlalchemy import func, select
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


class VgncCandidateRepository:
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

        ensembl_xref_subquery = (
            select(
                ensembl_gene_has_xrefs.genefam_id.label("genefam_id"),
                func.min(ensembl_xref.xref).label("ensembl_gene_id"),
            )
            .select_from(ensembl_gene_has_xrefs)
            .join(ensembl_xref, ensembl_xref.id == ensembl_gene_has_xrefs.xref_id)
            .join(
                ensembl_database_resource,
                ensembl_database_resource.id == ensembl_xref.external_db_id,
            )
            .where(ensembl_database_resource.db_name == _ENSEMBL_GENE_DB_NAME)
            .group_by(ensembl_gene_has_xrefs.genefam_id)
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
            .join(ensembl_xref_subquery, ensembl_xref_subquery.c.genefam_id == Genefam.genefam_id)
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

        return [
            GeneRecord(
                assigned_id=gene.assigned_id,
                assigned_symbol=gene.assigned_symbol or "",
                assigned_name=gene.assigned_name or "",
                status=status_display,
                species_display_name=gene.species.display_name,
                chromosome_display_name=_select_chromosome_display_name(gene.locations),
                ensembl_gene_id=ensembl_gene_id,
            )
            for gene, status_display, ensembl_gene_id in rows
        ]


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
