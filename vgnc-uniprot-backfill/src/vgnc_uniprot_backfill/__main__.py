from __future__ import annotations

import argparse
import logging
from collections.abc import Sequence

from dotenv import load_dotenv

from vgnc_uniprot_backfill.ensembl import (
    DEFAULT_MAX_PER_SECOND,
    DEFAULT_REQUEST_EXCEPTION_RETRY_DELAYS_SECONDS,
    DEFAULT_TIMEOUT_SECONDS,
    DEFAULT_USER_AGENT,
)
from vgnc_uniprot_backfill.pipeline import run_backfill

_LOG_LEVEL_CHOICES = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")


def _positive_int(value: str) -> int:
    parsed_value = int(value)
    if parsed_value <= 0:
        raise argparse.ArgumentTypeError("must be > 0")

    return parsed_value


def _non_negative_float(value: str) -> float:
    parsed_value = float(value)
    if parsed_value < 0:
        raise argparse.ArgumentTypeError("must be >= 0")

    return parsed_value


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m vgnc_uniprot_backfill",
        description="Backfill UniProt accessions for VGNC records missing local UniProt xrefs.",
    )
    parser.add_argument("--out", required=True, help="Output CSV file path")
    parser.add_argument("--taxon-id", type=int, default=None, help="Optional NCBI taxon filter")
    parser.add_argument(
        "--max-per-second",
        type=float,
        default=DEFAULT_MAX_PER_SECOND,
        help="Maximum Ensembl requests per second",
    )
    parser.add_argument(
        "--user-agent",
        default=DEFAULT_USER_AGENT,
        help="User-Agent header sent to Ensembl",
    )
    parser.add_argument(
        "--timeout-seconds",
        type=_positive_int,
        default=DEFAULT_TIMEOUT_SECONDS,
        help="Per-request timeout in seconds for Ensembl calls",
    )
    parser.add_argument(
        "--request-exception-retry-delays-seconds",
        type=_non_negative_float,
        nargs="*",
        default=list(DEFAULT_REQUEST_EXCEPTION_RETRY_DELAYS_SECONDS),
        help=(
            "Retry delays (seconds) after request exceptions (e.g. timeouts). "
            "Provide as space-separated values, e.g. --request-exception-retry-delays-seconds 30 60"
        ),
    )
    parser.add_argument(
        "--log-level",
        choices=_LOG_LEVEL_CHOICES,
        default="INFO",
        help="Logging level",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    load_dotenv(override=False)
    logging.basicConfig(level=getattr(logging, args.log_level), format="%(levelname)s %(message)s")

    run_backfill(
        out_path=args.out,
        taxon_id=args.taxon_id,
        max_per_second=args.max_per_second,
        user_agent=args.user_agent,
        timeout_seconds=args.timeout_seconds,
        request_exception_retry_delays_seconds=tuple(args.request_exception_retry_delays_seconds),
    )
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
