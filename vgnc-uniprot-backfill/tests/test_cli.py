from __future__ import annotations

from pathlib import Path

from vgnc_uniprot_backfill.__main__ import main
from vgnc_uniprot_backfill.ensembl import DEFAULT_MAX_PER_SECOND, DEFAULT_USER_AGENT
from vgnc_uniprot_backfill.pipeline import PipelineResult


def test_main_invokes_pipeline_with_cli_args(monkeypatch, tmp_path: Path) -> None:
    captured: dict[str, object] = {}

    def _fake_run_backfill(**kwargs: object) -> PipelineResult:
        captured.update(kwargs)
        return PipelineResult(
            candidate_genes=1,
            unique_ensembl_ids=1,
            report_rows=1,
            lookup_failures=0,
        )

    monkeypatch.setattr("vgnc_uniprot_backfill.__main__.run_backfill", _fake_run_backfill)

    out_path = tmp_path / "out.csv"
    exit_code = main(
        [
            "--out",
            str(out_path),
            "--taxon-id",
            "9031",
            "--max-per-second",
            "12.5",
            "--user-agent",
            "test-agent/1.0",
            "--log-level",
            "DEBUG",
        ]
    )

    assert exit_code == 0
    assert captured == {
        "out_path": str(out_path),
        "taxon_id": 9031,
        "max_per_second": 12.5,
        "user_agent": "test-agent/1.0",
    }


def test_main_uses_shared_ensembl_defaults(monkeypatch, tmp_path: Path) -> None:
    captured: dict[str, object] = {}

    def _fake_run_backfill(**kwargs: object) -> PipelineResult:
        captured.update(kwargs)
        return PipelineResult(
            candidate_genes=0,
            unique_ensembl_ids=0,
            report_rows=0,
            lookup_failures=0,
        )

    monkeypatch.setattr("vgnc_uniprot_backfill.__main__.run_backfill", _fake_run_backfill)

    out_path = tmp_path / "out.csv"
    exit_code = main(["--out", str(out_path)])

    assert exit_code == 0
    assert captured["max_per_second"] == DEFAULT_MAX_PER_SECOND
    assert captured["user_agent"] == DEFAULT_USER_AGENT
