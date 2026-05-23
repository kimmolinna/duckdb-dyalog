#!/usr/bin/env bash
# Download libduckdb.so for Linux amd64 into lib/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$ROOT/lib"
DUCKDB_VERSION="${DUCKDB_VERSION:-v1.1.3}"
ARCH="${DUCKDB_LINUX_ARCH:-linux-amd64}"
TARGET="$LIB_DIR/libduckdb.so"
ZIP_NAME="libduckdb-${ARCH}.zip"
URL="https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/${ZIP_NAME}"

if [[ -f "$TARGET" ]]; then
  echo "DuckDB library already present: $TARGET"
  exit 0
fi

mkdir -p "$LIB_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading DuckDB ${DUCKDB_VERSION} (${ARCH})..."
curl -fsSL "$URL" -o "$TMP/${ZIP_NAME}"
unzip -j "$TMP/${ZIP_NAME}" "libduckdb.so*" -d "$TMP"
install -m 644 "$TMP"/libduckdb.so* "$TARGET"
echo "Installed $TARGET"
