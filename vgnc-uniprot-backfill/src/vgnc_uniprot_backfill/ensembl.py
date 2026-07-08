from __future__ import annotations

import logging
import time
from dataclasses import dataclass
from typing import Any

import requests

DEFAULT_BASE_URL = "https://rest.ensembl.org"
DEFAULT_MAX_PER_SECOND = 15.0
DEFAULT_TIMEOUT_SECONDS = 30
DEFAULT_USER_AGENT = "vgnc-uniprot-backfill/0.1"


@dataclass(frozen=True)
class UniprotXref:
    accession: str
    source: str


@dataclass(frozen=True)
class UniprotLookupResult:
    xrefs: list[UniprotXref]
    failed: bool


class EnsemblXrefClient:
    def __init__(
        self,
        *,
        session: requests.Session | None = None,
        base_url: str = DEFAULT_BASE_URL,
        max_per_second: float = DEFAULT_MAX_PER_SECOND,
        timeout_seconds: int = DEFAULT_TIMEOUT_SECONDS,
        user_agent: str = DEFAULT_USER_AGENT,
        logger: logging.Logger | None = None,
    ) -> None:
        if max_per_second <= 0:
            raise ValueError("max_per_second must be > 0")

        self._session = session or requests.Session()
        self._session.headers.update(
            {
                "Accept": "application/json",
                "User-Agent": user_agent,
            }
        )

        self._base_url = base_url.rstrip("/")
        self._timeout_seconds = timeout_seconds
        self._min_request_interval_seconds = 1.0 / max_per_second
        self._last_request_started_at: float | None = None
        self._logger = logger or logging.getLogger(__name__)
        self.last_lookup_failed = False

    def fetch_uniprot_xrefs(self, ensembl_gene_id: str) -> list[UniprotXref]:
        result = self.lookup_uniprot_xrefs(ensembl_gene_id)
        self.last_lookup_failed = result.failed
        return result.xrefs

    def lookup_uniprot_xrefs(self, ensembl_gene_id: str) -> UniprotLookupResult:
        response = self._request_once(ensembl_gene_id)
        if response is None:
            return UniprotLookupResult(xrefs=[], failed=True)

        if response.status_code == 429:
            retry_after_seconds = _parse_retry_after_seconds(response.headers.get("Retry-After"))
            if retry_after_seconds > 0:
                time.sleep(retry_after_seconds)
            response = self._request_once(ensembl_gene_id)
            if response is None:
                return UniprotLookupResult(xrefs=[], failed=True)

        if response.status_code >= 400:
            self._logger.warning(
                "Ensembl request failed for %s with status %s",
                ensembl_gene_id,
                response.status_code,
            )
            return UniprotLookupResult(xrefs=[], failed=True)

        try:
            payload = response.json()
        except ValueError:
            self._logger.warning("Invalid JSON payload from Ensembl for %s", ensembl_gene_id)
            return UniprotLookupResult(xrefs=[], failed=True)

        if not isinstance(payload, list):
            return UniprotLookupResult(xrefs=[], failed=True)

        return UniprotLookupResult(xrefs=_extract_uniprot_xrefs(payload), failed=False)

    def _request_once(self, ensembl_gene_id: str) -> Any | None:
        self._throttle()
        self._last_request_started_at = time.monotonic()

        try:
            return self._session.get(
                f"{self._base_url}/xrefs/id/{ensembl_gene_id}",
                params={
                    "all_levels": 1,
                    "external_db": "Uniprot%",
                },
                timeout=self._timeout_seconds,
            )
        except requests.RequestException:
            self._logger.exception("Request to Ensembl failed for %s", ensembl_gene_id)
            return None

    def _throttle(self) -> None:
        if self._last_request_started_at is None:
            return

        elapsed = time.monotonic() - self._last_request_started_at
        remaining = self._min_request_interval_seconds - elapsed
        if remaining > 0:
            time.sleep(remaining)


def _extract_uniprot_xrefs(payload: list[dict[str, object]]) -> list[UniprotXref]:
    xrefs: list[UniprotXref] = []
    seen_accessions: set[str] = set()

    for row in payload:
        dbname = row.get("dbname")
        primary_id = row.get("primary_id")

        if not isinstance(dbname, str) or not dbname.startswith("Uniprot/"):
            continue
        if not isinstance(primary_id, str) or not primary_id:
            continue
        if primary_id in seen_accessions:
            continue

        seen_accessions.add(primary_id)
        source = dbname.split("/", 1)[1] if "/" in dbname else ""
        xrefs.append(UniprotXref(accession=primary_id, source=source))

    return xrefs


def _parse_retry_after_seconds(retry_after_header: str | None) -> float:
    if retry_after_header is None:
        return 0.0

    try:
        retry_after_seconds = float(retry_after_header)
    except ValueError:
        return 0.0

    if retry_after_seconds < 0:
        return 0.0

    return retry_after_seconds
