#!/usr/bin/env bash
# Build libduckdb_arrow_ipc.so and optional test binary.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$ROOT/lib"
NANOARROW_DIR="$LIB_DIR/nanoarrow"
NANOARROW_VERSION="apache-arrow-nanoarrow-0.8.0"
NANOARROW_CFLAGS=(-DNANOARROW_NAMESPACE=DuckDbDyalog -I"$NANOARROW_DIR/include" -I"$LIB_DIR" -O2 -fPIC)
NANOARROW_SRC=(
  "$NANOARROW_DIR/src/nanoarrow.c"
  "$NANOARROW_DIR/src/nanoarrow_ipc.c"
  "$NANOARROW_DIR/src/flatcc.c"
)

if [[ ! -f "$NANOARROW_DIR/src/nanoarrow_ipc.c" ]]; then
  echo "nanoarrow sources missing. Run:" >&2
  echo "  bash scripts/vendor-nanoarrow.sh" >&2
  exit 1
fi

if [[ ! -f "$LIB_DIR/libduckdb.so" && ! -f "$LIB_DIR/libduckdb.dylib" && ! -f "$LIB_DIR/duckdb.dll" ]]; then
  echo "DuckDB library missing in lib/. Run scripts/download-duckdb-linux.sh (Linux) or place libduckdb.dylib locally." >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    DUCKDB_LIB="$LIB_DIR/libduckdb.dylib"
    SHIM_OUT="$LIB_DIR/libduckdb_arrow_ipc.dylib"
    ;;
  Linux)
    DUCKDB_LIB="$LIB_DIR/libduckdb.so"
    SHIM_OUT="$LIB_DIR/libduckdb_arrow_ipc.so"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    DUCKDB_LIB="$LIB_DIR/duckdb.dll"
    SHIM_OUT="$LIB_DIR/libduckdb_arrow_ipc.dll"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$DUCKDB_LIB" ]]; then
  echo "Expected DuckDB library not found: $DUCKDB_LIB" >&2
  exit 1
fi

echo "Building Arrow export shim -> $SHIM_OUT"
gcc -shared "${NANOARROW_CFLAGS[@]}" \
  -o "$SHIM_OUT" \
  "$LIB_DIR/duckdb_arrow_export.c" \
  "${NANOARROW_SRC[@]}" \
  -L"$LIB_DIR" -lduckdb \
  -Wl,-rpath,"$LIB_DIR"

if [[ "${1:-}" != "--no-test" ]]; then
  TEST_BIN="$LIB_DIR/test_arrow_export"
  echo "Building test binary -> $TEST_BIN"
  gcc "${NANOARROW_CFLAGS[@]}" \
    -o "$TEST_BIN" \
    "$LIB_DIR/test_arrow_export.c" \
    "$LIB_DIR/duckdb_arrow_export.c" \
    "${NANOARROW_SRC[@]}" \
    -L"$LIB_DIR" -lduckdb \
    -Wl,-rpath,"$LIB_DIR"

  OUT_FILE="$(mktemp -t plot-test.XXXXXX.arrows)"
  trap 'rm -f "$OUT_FILE"' EXIT
  export DYLD_LIBRARY_PATH="$LIB_DIR:${DYLD_LIBRARY_PATH:-}"
  export LD_LIBRARY_PATH="$LIB_DIR:${LD_LIBRARY_PATH:-}"
  "$TEST_BIN" "$OUT_FILE"
  echo "Arrow export smoke test OK ($(wc -c <"$OUT_FILE" | tr -d ' ') bytes -> $OUT_FILE)"
fi

echo "Done."
