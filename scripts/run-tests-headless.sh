#!/usr/bin/env bash
# One-shot headless test run (no RIDE). Exits non-zero on failure.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/scripts/download-duckdb-linux.sh"

if [[ ! -f "$ROOT/lib/nanoarrow/src/nanoarrow_ipc.c" ]]; then
  bash "$ROOT/scripts/vendor-nanoarrow.sh"
fi

bash "$ROOT/scripts/build-arrow-export-shim.sh" --no-test
gcc -shared -fPIC -o "$ROOT/lib/libduckdb_shim.so" "$ROOT/lib/duckdb_shim.c" -L"$ROOT/lib" -lduckdb -Wl,-rpath,"$ROOT/lib"

docker run --rm \
  -v "$ROOT:/workspace:rw" \
  -e LOAD=/workspace/scripts/cloudRunOnce.aplf \
  -e LD_LIBRARY_PATH=/workspace/lib \
  dyalog/dyalog:20.0
