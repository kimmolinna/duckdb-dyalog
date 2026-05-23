# duckdb-dyalog

Dyalog APL bindings for DuckDB via the C API.

## Cursor Cloud specific instructions

This repository supports automated APL testing in [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent) using Dyalog 20 in Docker with RIDE over TCP (Zero Footprint HTTP).

### Environment

Cloud agent configuration lives in [`.cursor/environment.json`](.cursor/environment.json):

- Builds a Ubuntu image with Docker-in-Docker (see [`.cursor/Dockerfile`](.cursor/Dockerfile))
- Runs [`.cursor/install.sh`](.cursor/install.sh) to pull `dyalog/dyalog:20.0` and download `lib/libduckdb.so`
- Starts a long-lived Dyalog+RIDE service via `docker compose`

### Starting Dyalog + RIDE

From the repo root:

```bash
docker compose -f docker/docker-compose.yml up -d
docker compose -f docker/docker-compose.yml ps
```

Open Zero Footprint RIDE in a browser (Computer Use or local):

```
http://127.0.0.1:8888
```

The Dyalog container loads [`scripts/cloudBootstrap.aplf`](scripts/cloudBootstrap.aplf) on startup, which:

1. Links the repo as namespace `duck` via `⎕SE.Link.Create`
2. Calls `duck.db.init '/workspace/lib/'`
3. Waits for a RIDE connection (TCP session stays open for reuse)

### Running tests in a RIDE session

After connecting to RIDE once, run tests in the same session (no container restart needed):

```apl
duck.db.runTests 'smoke'
duck.db.runTests 'phase1'
duck.db.runTests 'full'
duck.db.runAllTests
```

Individual suites live under `duck.db.tests.*` (files in `db/tests/`). Check `3501⌶0` to verify RIDE is connected.

### After editing APL source

Linux Link does not watch directories. Refresh before re-running tests:

```apl
]link.refresh duck
duck.db.runTests 'smoke'
```

### Headless CI (no RIDE)

For one-shot runs without an interactive session:

```bash
bash scripts/run-tests-headless.sh
```

### DuckDB Linux library

`lib/libduckdb.so` is downloaded by [`scripts/download-duckdb-linux.sh`](scripts/download-duckdb-linux.sh) (default version `v1.5.2`, override with `DUCKDB_VERSION`).

### Linux x86-64 ABI shim (`libduckdb_shim.so`)

Dyalog 20 on Linux x86-64 cannot correctly pass the 48-byte `duckdb_result` struct by value to `duckdb_fetch_chunk`. A small C shim library (`lib/libduckdb_shim.so`) wraps this call, accepting the struct by pointer instead. The shim is built by `.cursor/install.sh` and loaded automatically by `api.init` on Linux when present. If you see a segfault in `duckdb_fetch_chunk`, rebuild the shim:

```bash
docker run --rm --entrypoint bash --user root -v /workspace:/workspace:rw dyalog/dyalog:20.0 -c \
  'apt-get update -qq && apt-get install -y -qq gcc > /dev/null 2>&1 && gcc -shared -fPIC -o /workspace/lib/libduckdb_shim.so /workspace/lib/duckdb_shim.c -L/workspace/lib -lduckdb -Wl,-rpath,/workspace/lib'
```

### Interacting with the Dyalog container

If RIDE HTTP (port 8888) does not respond in a browser, use `docker exec` for direct APL REPL access:

```bash
docker exec -it docker-dyalog-1 /opt/mdyalog/20.0/64/unicode/dyalog +s
```

Then link and init manually if needed:

```apl
{}⎕SE.Link.Create 'duck' '/workspace'
duck.db.init '/workspace/lib/'
```

### Troubleshooting

| Issue | Action |
|-------|--------|
| `libduckdb.so` missing | Run `bash scripts/download-duckdb-linux.sh` |
| `libduckdb_shim.so` missing | Rebuild with the gcc command above |
| RIDE page not loading | Use `docker exec` instead (see above) |
| Stale code after edits | `]link.refresh duck` |
| Port 8888 in use | Stop other services or change port mapping in `docker/docker-compose.yml` |
| Segfault in `duckdb_fetch_chunk` | Rebuild shim or check DuckDB version matches `v1.5.2` |
