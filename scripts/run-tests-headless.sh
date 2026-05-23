#!/usr/bin/env bash
# One-shot headless test run (no RIDE). Exits non-zero on failure.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/scripts/download-duckdb-linux.sh"

docker run --rm \
  -v "$ROOT:/workspace:rw" \
  -e LOAD=/workspace/scripts/cloudRunOnce.aplf \
  -e LD_LIBRARY_PATH=/workspace/lib \
  dyalog/dyalog:20.0
