#!/usr/bin/env bash
# Start (or recreate) the Dyalog+RIDE stack so compose/env changes take effect.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

docker compose -f docker/docker-compose.yml up --force-recreate --remove-orphans
