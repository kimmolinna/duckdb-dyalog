#!/usr/bin/env bash
# Vendor nanoarrow 0.8.0 (bundled C sources + headers) into lib/nanoarrow/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/lib/nanoarrow"
VERSION="apache-arrow-nanoarrow-0.8.0"
TARBALL="/tmp/nanoarrow-${VERSION}.tar.gz"
URL="https://github.com/apache/arrow-nanoarrow/archive/refs/tags/${VERSION}.tar.gz"

if [[ ! -f "$TARBALL" ]]; then
  echo "Downloading $URL ..."
  curl -fsSL "$URL" -o "$TARBALL"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
tar -xzf "$TARBALL" -C "$TMP"

python3 "$TMP/arrow-nanoarrow-${VERSION}/ci/scripts/bundle.py" \
  --output-dir "$OUT_DIR" \
  --symbol-namespace DuckDbDyalog \
  --with-ipc \
  --with-flatcc

echo "$VERSION" >"$OUT_DIR/VERSION"
echo "Vendored nanoarrow into $OUT_DIR"
