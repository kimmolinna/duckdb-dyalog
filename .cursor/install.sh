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

echo "Building Linux ABI shim (libduckdb_shim.so)..."
if [[ ! -f "$ROOT/lib/libduckdb_shim.so" ]]; then
  docker run --rm --entrypoint bash --user root -v "$ROOT:/workspace:rw" dyalog/dyalog:20.0 -c \
    'apt-get update -qq && apt-get install -y -qq gcc > /dev/null 2>&1 && gcc -shared -fPIC -o /workspace/lib/libduckdb_shim.so /workspace/lib/duckdb_shim.c -L/workspace/lib -lduckdb -Wl,-rpath,/workspace/lib' \
    && echo "Shim built OK" || echo "Shim build failed (non-fatal)"
fi

echo "Cloud agent install complete."
