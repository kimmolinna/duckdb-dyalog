#!/usr/bin/env bash
# Download DuckDB binaries and C/C++ headers into lib/ for the pinned release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$ROOT/lib"
DUCKDB_VERSION="${DUCKDB_VERSION:-v1.5.3}"
VERSION_FILE="$LIB_DIR/.duckdb-version"
BASE_URL="https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}"

if [[ -f "$VERSION_FILE" ]] && [[ "$(cat "$VERSION_FILE")" == "$DUCKDB_VERSION" ]] \
    && [[ -f "$LIB_DIR/libduckdb.so" ]] \
    && [[ -f "$LIB_DIR/duckdb.h" ]] \
    && [[ -f "$LIB_DIR/duckdb.hpp" ]] \
    && [[ -f "$LIB_DIR/duckdb.dll" ]]; then
  echo "DuckDB ${DUCKDB_VERSION} assets already present in ${LIB_DIR}"
  exit 0
fi

mkdir -p "$LIB_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading DuckDB ${DUCKDB_VERSION}..."

echo "  libduckdb-linux-amd64.zip"
curl -fsSL "${BASE_URL}/libduckdb-linux-amd64.zip" -o "$TMP/libduckdb-linux-amd64.zip"
unzip -j "$TMP/libduckdb-linux-amd64.zip" "libduckdb.so*" -d "$TMP"
install -m 644 "$TMP"/libduckdb.so* "$LIB_DIR/libduckdb.so"

echo "  libduckdb-windows-amd64.zip"
curl -fsSL "${BASE_URL}/libduckdb-windows-amd64.zip" -o "$TMP/libduckdb-windows-amd64.zip"
unzip -j "$TMP/libduckdb-windows-amd64.zip" "duckdb.dll" -d "$TMP"
install -m 644 "$TMP/duckdb.dll" "$LIB_DIR/duckdb.dll"

echo "  libduckdb-src.zip (headers)"
curl -fsSL "${BASE_URL}/libduckdb-src.zip" -o "$TMP/libduckdb-src.zip"
unzip -j "$TMP/libduckdb-src.zip" "duckdb.h" "duckdb.hpp" -d "$TMP"
install -m 644 "$TMP/duckdb.h" "$LIB_DIR/duckdb.h"
install -m 644 "$TMP/duckdb.hpp" "$LIB_DIR/duckdb.hpp"

echo "$DUCKDB_VERSION" > "$VERSION_FILE"
echo "Installed DuckDB ${DUCKDB_VERSION} into ${LIB_DIR}"
