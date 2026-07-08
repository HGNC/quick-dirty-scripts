from __future__ import annotations

import time
from unittest.mock import Mock

import requests

from vgnc_uniprot_backfill.ensembl import EnsemblXrefClient


class _StubResponse:
    def __init__(
        self,
        status_code: int,
        payload: list[dict[str, object]],
        headers: dict[str, str] | None = None,
    ) -> None:
        self.status_code = status_code
        self._payload = payload
        self.headers = headers or {}

    def json(self) -> list[dict[str, object]]:
        return self._payload


def test_fetch_uniprot_xrefs_includes_required_query_params() -> None:
    session = requests.Session()
    session.get = Mock(return_value=_StubResponse(200, []))

    client = EnsemblXrefClient(session=session)
    client.fetch_uniprot_xrefs("ENSG00000139618")

    args, kwargs = session.get.call_args
    assert args[0].endswith("/xrefs/id/ENSG00000139618")
    assert kwargs["params"]["all_levels"] == 1
    assert kwargs["params"]["external_db"] == "Uniprot%"


def test_fetch_uniprot_xrefs_throttles_to_max_requests_per_second() -> None:
    call_times: list[float] = []

    def _capture_call(*args: object, **kwargs: object) -> _StubResponse:
        call_times.append(time.monotonic())
        return _StubResponse(200, [])

    session = requests.Session()
    session.get = Mock(side_effect=_capture_call)

    client = EnsemblXrefClient(session=session, max_per_second=15)
    client.fetch_uniprot_xrefs("ENSG00000139618")
    client.fetch_uniprot_xrefs("ENSG00000157764")

    assert len(call_times) == 2
    assert call_times[1] - call_times[0] >= (1 / 15)


def test_fetch_uniprot_xrefs_retries_after_429_with_retry_after_header(monkeypatch) -> None:
    responses = iter(
        [
            _StubResponse(429, [], headers={"Retry-After": "1"}),
            _StubResponse(
                200,
                [{"dbname": "Uniprot/SWISSPROT", "primary_id": "P12345"}],
            ),
        ]
    )

    sleeps: list[float] = []
    monkeypatch.setattr(
        "vgnc_uniprot_backfill.ensembl.time.sleep",
        lambda value: sleeps.append(value),
    )

    session = requests.Session()
    session.get = Mock(side_effect=lambda *args, **kwargs: next(responses))

    client = EnsemblXrefClient(session=session)
    xrefs = client.fetch_uniprot_xrefs("ENSG00000139618")

    assert [xref.accession for xref in xrefs] == ["P12345"]
    assert session.get.call_count == 2
    assert 1.0 in sleeps


def test_fetch_uniprot_xrefs_returns_empty_list_on_server_error() -> None:
    session = requests.Session()
    session.get = Mock(return_value=_StubResponse(503, []))

    client = EnsemblXrefClient(session=session)

    assert client.fetch_uniprot_xrefs("ENSG00000139618") == []


def test_fetch_uniprot_xrefs_extracts_unique_uniprot_primary_ids_only() -> None:
    session = requests.Session()
    session.get = Mock(
        return_value=_StubResponse(
            200,
            [
                {"dbname": "Uniprot/SWISSPROT", "primary_id": "P12345"},
                {"dbname": "Uniprot/SPTREMBL", "primary_id": "Q11111"},
                {"dbname": "EntrezGene", "primary_id": "123"},
                {"dbname": "uniprot/swissprot", "primary_id": "Q22222"},
                {"dbname": "Uniprot/SWISSPROT", "primary_id": "P12345"},
                {"dbname": "Uniprot/SWISSPROT", "primary_id": ""},
            ],
        )
    )

    client = EnsemblXrefClient(session=session)

    xrefs = client.fetch_uniprot_xrefs("ENSG00000139618")

    assert [xref.accession for xref in xrefs] == ["P12345", "Q11111"]
