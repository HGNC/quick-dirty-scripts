#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.mysql-test.yml"
CONTAINER_NAME="vgnc-uniprot-backfill-mysql-test"

cleanup() {
  docker compose -f "$COMPOSE_FILE" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[db-test] Starting MySQL test container..."
docker compose -f "$COMPOSE_FILE" up -d

echo "[db-test] Waiting for MySQL healthcheck..."
for _ in $(seq 1 60); do
  health="$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || true)"
  if [[ "$health" == "healthy" ]]; then
    break
  fi
  sleep 1
done

health="$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || true)"
if [[ "$health" != "healthy" ]]; then
  echo "[db-test] MySQL container did not become healthy in time." >&2
  exit 1
fi

if [[ -n "${VGNC_PUBLIC_SQL_DUMP:-}" ]]; then
  if [[ ! -f "$VGNC_PUBLIC_SQL_DUMP" ]]; then
    echo "[db-test] VGNC_PUBLIC_SQL_DUMP file not found: $VGNC_PUBLIC_SQL_DUMP" >&2
    exit 1
  fi

  echo "[db-test] Importing SQL dump: $VGNC_PUBLIC_SQL_DUMP"
  cat "$VGNC_PUBLIC_SQL_DUMP" \
    | docker compose -f "$COMPOSE_FILE" exec -T mysql \
      mysql -uroot -proot vgnc_public
fi

export DB_HOST=127.0.0.1
export DB_PORT=3307
export DB_NAME=vgnc_public
export DB_USER=vgnc
export DB_PASSWORD=vgnc

echo "[db-test] Running integration tests..."
cd "$ROOT_DIR"
uv run pytest tests/test_db.py -q
