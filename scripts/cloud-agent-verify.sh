#!/usr/bin/env bash
# Print versions and config fingerprint for Cloud Agent debugging.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Cloud Agent environment verify ==="
echo "Repo: $(basename "$ROOT")"
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
echo "Environment config: .cursor/environment.json"
if [[ -f .cursor/environment.json ]]; then
  python3 -c "import json; print('  install:', json.load(open('.cursor/environment.json')).get('install',''))" 2>/dev/null || true
fi
echo "DuckDB pinned: $(cat lib/.duckdb-version 2>/dev/null || echo 'not installed — run scripts/download-duckdb-linux.sh')"
echo "Compose RIDE_INIT: $(grep RIDE_INIT docker/docker-compose.yml | head -1 || echo 'missing')"
echo "Docker: $(docker --version 2>/dev/null || echo 'not available')"
echo "Dyalog image: $(docker image inspect dyalog/dyalog:20.0 --format '{{.Id}}' 2>/dev/null | cut -c1-12 || echo 'not pulled')"
echo "Compose status:"
docker compose -f docker/docker-compose.yml ps 2>/dev/null || echo "  (compose not running)"
echo "======================================"
