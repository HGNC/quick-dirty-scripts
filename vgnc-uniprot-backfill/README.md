# vgnc-uniprot-backfill

A small utility that finds approved VGNC genes which have an Ensembl gene ID but
no UniProt accession stored locally, derives a UniProt accession from the Ensembl
REST API, and writes the results to a CSV.

Full specification: `../.ai/specs/vgnc-uniprot-backfill.md`.

## Setup

```bash
uv sync --extra dev
cp .env.example .env   # then fill in DB_* credentials
```

## Verify bootstrap (T1)

```bash
uv run python -c "import vgnc_orm, requests, dotenv; print('ok')"
```

## Tests

```bash
uv run pytest -q
```

### DB integration tests (`tests/test_db.py`)

- These tests require a reachable `vgnc_public` MySQL database.
- If required `DB_*` env vars are missing (or left as placeholders), the DB
  tests are skipped instead of failing.

### Live Ensembl CLI smoke test (`tests/test_cli_integration.py`)

- This test calls the live Ensembl REST API and is opt-in.
- To run it, set `RUN_EXTERNAL_ENSEMBL=1` and provide a reachable `vgnc_public`
  database config in env vars / `.env`.

## Run integration tests with Docker MySQL (local)

1. Start a local MySQL test container and run DB tests:

   ```bash
   ./scripts/run-db-integration-tests.sh
   ```

2. Optional: import a `vgnc_public` SQL dump before running tests:

   ```bash
   VGNC_PUBLIC_SQL_DUMP=/absolute/path/to/vgnc_public.sql \
   ./scripts/run-db-integration-tests.sh
   ```

Notes:
- Docker setup file: `docker-compose.mysql-test.yml`
- Container DB credentials used by the script:
  - `DB_HOST=127.0.0.1`
  - `DB_PORT=3307`
  - `DB_NAME=vgnc_public`
  - `DB_USER=vgnc`
  - `DB_PASSWORD=vgnc`

## CI (GitHub Actions)

Workflow file: `.github/workflows/vgnc-uniprot-backfill-ci.yml`

- `lint-and-unit` job runs on PRs/pushes affecting this project.
- `integration-db` job runs with a MySQL service container and imports a DB dump,
  then executes `tests/test_db.py`.
- Integration job is conditional and runs when either:
  - repo secret `VGNC_PUBLIC_SQL_DUMP_URL` is set, or
  - workflow is manually dispatched with `dump_url` input.

The dump URL may point to `.sql` or `.sql.gz`.

## Run (implemented in T6)

The CLI entrypoint (`python -m vgnc_uniprot_backfill --out ...`) is added in
Task T6.
