#!/usr/bin/env bash
# Cursor Cloud Agent install: Docker setup, Dyalog image, DuckDB Linux library
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

configure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not found; skipping daemon configuration"
    return 0
  fi

  if [[ ! -f /etc/docker/daemon.json ]]; then
    sudo mkdir -p /etc/docker
    printf '%s\n' '{' '  "storage-driver": "fuse-overlayfs"' '}' | sudo tee /etc/docker/daemon.json >/dev/null
  fi

  if command -v service >/dev/null 2>&1; then
    sudo service docker start || true
  fi
}

configure_docker

echo "Pulling dyalog/dyalog:20.0..."
docker pull dyalog/dyalog:20.0

echo "Ensuring DuckDB Linux library..."
bash "$ROOT/scripts/download-duckdb-linux.sh"

if [[ ! -f "$ROOT/lib/nanoarrow/src/nanoarrow_ipc.c" ]]; then
  echo "Vendoring nanoarrow..."
  bash "$ROOT/scripts/vendor-nanoarrow.sh"
fi

echo "Building DuckDB C shims..."
bash "$ROOT/scripts/build-arrow-export-shim.sh" --no-test
if [[ "$(uname -s)" == "Linux" ]]; then
  gcc -shared -fPIC -o "$ROOT/lib/libduckdb_shim.so" "$ROOT/lib/duckdb_shim.c" -L"$ROOT/lib" -lduckdb -Wl,-rpath,"$ROOT/lib"
fi

echo ""
bash "$ROOT/scripts/cloud-agent-verify.sh"
echo ""
echo "Cloud agent install complete."
