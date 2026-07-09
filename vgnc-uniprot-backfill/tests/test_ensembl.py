from __future__ import annotations

import logging
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


def test_lookup_uniprot_xrefs_retries_request_errors_before_success(monkeypatch) -> None:
    responses = iter(
        [
            requests.ReadTimeout("timeout-1"),
            requests.ReadTimeout("timeout-2"),
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
    request_timeouts: list[float] = []

    def _get(*args: object, **kwargs: object) -> _StubResponse:
        request_timeouts.append(kwargs["timeout"])
        response = next(responses)
        if isinstance(response, Exception):
            raise response
        return response

    session.get = Mock(side_effect=_get)

    client = EnsemblXrefClient(session=session)
    result = client.lookup_uniprot_xrefs("ENSG00000139618")

    assert result.failed is False
    assert [xref.accession for xref in result.xrefs] == ["P12345"]
    assert session.get.call_count == 3
    assert request_timeouts == [30, 60, 90]
    assert 30.0 in sleeps
    assert 60.0 in sleeps


def test_lookup_uniprot_xrefs_retries_connection_errors_without_timeout_increase(
    monkeypatch,
) -> None:
    responses = iter(
        [
            requests.ConnectionError("connection-1"),
            requests.ConnectionError("connection-2"),
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
    request_timeouts: list[float] = []

    def _get(*args: object, **kwargs: object) -> _StubResponse:
        request_timeouts.append(kwargs["timeout"])
        response = next(responses)
        if isinstance(response, Exception):
            raise response
        return response

    session.get = Mock(side_effect=_get)

    client = EnsemblXrefClient(session=session)
    result = client.lookup_uniprot_xrefs("ENSG00000139618")

    assert result.failed is False
    assert [xref.accession for xref in result.xrefs] == ["P12345"]
    assert session.get.call_count == 3
    assert request_timeouts == [30, 30, 30]
    assert 30.0 in sleeps
    assert 60.0 in sleeps


def test_lookup_uniprot_xrefs_does_not_retry_other_request_exceptions(caplog) -> None:
    session = requests.Session()
    session.get = Mock(side_effect=requests.exceptions.InvalidURL("bad url"))

    logger = logging.getLogger("vgnc_uniprot_backfill.test.ensembl.requestexception")
    client = EnsemblXrefClient(session=session, logger=logger)

    with caplog.at_level(logging.WARNING, logger=logger.name):
        result = client.lookup_uniprot_xrefs("ENSG00000139618")

    assert result.xrefs == []
    assert result.failed is True
    assert result.status_code is None
    assert session.get.call_count == 1
    assert "without retry (InvalidURL)" in caplog.text


def test_lookup_uniprot_xrefs_logs_error_after_all_retry_attempts(monkeypatch, caplog) -> None:
    monkeypatch.setattr(
        "vgnc_uniprot_backfill.ensembl.time.sleep",
        lambda value: None,
    )

    session = requests.Session()
    session.get = Mock(side_effect=requests.ReadTimeout("timed out"))

    logger = logging.getLogger("vgnc_uniprot_backfill.test.ensembl")
    client = EnsemblXrefClient(session=session, logger=logger)

    with caplog.at_level(logging.WARNING, logger=logger.name):
        result = client.lookup_uniprot_xrefs("ENSG00000139618")

    assert result.xrefs == []
    assert result.failed is True
    assert result.status_code is None
    assert session.get.call_count == 3
    assert "attempt 1/3" in caplog.text
    assert "attempt 2/3" in caplog.text
    assert "after 3 attempts" in caplog.text


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


def test_lookup_uniprot_xrefs_marks_failures_explicitly() -> None:
    session = requests.Session()
    session.get = Mock(return_value=_StubResponse(503, []))

    client = EnsemblXrefClient(session=session)
    result = client.lookup_uniprot_xrefs("ENSG00000139618")

    assert result.xrefs == []
    assert result.failed is True
    assert result.status_code == 503
