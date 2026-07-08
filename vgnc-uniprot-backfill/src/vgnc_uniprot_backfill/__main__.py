from __future__ import annotations

import argparse
import logging
from collections.abc import Sequence

from dotenv import load_dotenv

from vgnc_uniprot_backfill.ensembl import DEFAULT_MAX_PER_SECOND, DEFAULT_USER_AGENT
from vgnc_uniprot_backfill.pipeline import run_backfill

_LOG_LEVEL_CHOICES = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")


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
    )
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
