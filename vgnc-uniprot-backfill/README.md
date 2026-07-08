# vgnc-uniprot-backfill

A small utility that finds approved VGNC genes which have an Ensembl gene ID but
no UniProt accession stored locally, derives UniProt accessions from the Ensembl
REST API, and writes the results to a CSV.

Full specification: `../.ai/specs/vgnc-uniprot-backfill.md`.

## Setup

```bash
uv sync --extra dev
cp .env.example .env
```

Then edit `.env` with real database credentials.

> Note: `vgnc_orm` uses `mysqlclient`, so your system must have MySQL client/dev
> libraries available for dependency installation.

## Database connection requirements

The CLI and DB-backed tests require a reachable **MySQL `vgnc_public`** database.
The script uses `vgnc_orm` and opens a **read-only session**.

Required environment variables:

| Variable | Required | Example | Notes |
|---|---|---|---|
| `DB_HOST` | yes | `localhost` | MySQL hostname or IP |
| `DB_PORT` | yes | `3306` | MySQL port |
| `DB_NAME` | yes | `vgnc_public` | Database/schema name |
| `DB_USER` | yes | `vgnc_reader` | DB user with read access |
| `DB_PASSWORD` | yes | `secret` | DB password |

You can provide these either via shell env vars or `.env` in the project root.
`python -m vgnc_uniprot_backfill` loads `.env` automatically.

## Quick verification

Check dependencies:

```bash
uv run python -c "import vgnc_orm, requests, dotenv; print('ok')"
```

Check DB connectivity (after setting `DB_*`):

```bash
uv run python - <<'PY'
from sqlalchemy import text
from vgnc_orm import get_readonly_session, initialize_engine

initialize_engine()
with get_readonly_session() as session:
    session.execute(text("SELECT 1"))

print("db ok")
PY
```

## Run the backfill CLI

```bash
uv run python -m vgnc_uniprot_backfill --out out.csv --taxon-id 9031
```

Useful options:

- `--out` (required): output CSV path
- `--taxon-id`: optional species filter (for faster smoke runs)
- `--max-per-second`: Ensembl API rate cap (default `15.0`)
- `--user-agent`: custom Ensembl User-Agent
- `--log-level`: `DEBUG|INFO|WARNING|ERROR|CRITICAL`

## Tests

Run all tests:

```bash
uv run pytest -q
```

### DB integration tests (`tests/test_db.py`)

- Require configured `DB_*` vars and a reachable `vgnc_public` MySQL database.
- If DB settings are missing or placeholders, tests are skipped.

### Live Ensembl CLI smoke test (`tests/test_cli_integration.py`)

This test is opt-in because it calls the live Ensembl API.

```bash
RUN_EXTERNAL_ENSEMBL=1 uv run pytest tests/test_cli_integration.py -q
```

It also requires valid `DB_*` env vars.

## Run DB integration tests with Docker MySQL (local)

1. Start a local MySQL test container and run DB tests:

   ```bash
   ./scripts/run-db-integration-tests.sh
   ```

2. Optional: import a `vgnc_public` SQL dump first:

   ```bash
   VGNC_PUBLIC_SQL_DUMP=/absolute/path/to/vgnc_public.sql \
   ./scripts/run-db-integration-tests.sh
   ```

Docker helper defaults used by the script:

- `DB_HOST=127.0.0.1`
- `DB_PORT=3307`
- `DB_NAME=vgnc_public`
- `DB_USER=vgnc`
- `DB_PASSWORD=vgnc`

## CI (GitHub Actions)

Workflow: `.github/workflows/vgnc-uniprot-backfill-ci.yml`

- `lint-and-unit` job runs on PRs/pushes affecting this project.
- `integration-db` job runs with a MySQL service container, imports a DB dump,
  then executes `tests/test_db.py`.
- Integration job is conditional and runs when either:
  - repo secret `VGNC_PUBLIC_SQL_DUMP_URL` is set, or
  - workflow is manually dispatched with `dump_url` input.

The dump URL may point to `.sql` or `.sql.gz`.
