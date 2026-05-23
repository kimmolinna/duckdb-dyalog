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

**Important:** Use `RIDE_INIT=http:*:8888` (with `*`), not `http::8888`. An empty address binds to loopback inside the container only, so Docker port mapping (`8888:8888`) cannot reach the RIDE server. The official [`dyalog/dyalog` image docs](https://hub.docker.com/r/dyalog/dyalog) use `http:*:8888`.

For a native RIDE client (not browser), map port 4502 and use `RIDE_INIT=serve:*:4502`.

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

DuckDB **v1.5.3** is the pinned release. Run:

```bash
bash scripts/download-duckdb-linux.sh
```

This installs `lib/libduckdb.so` (Linux), updates `lib/duckdb.dll` (Windows), and syncs `lib/duckdb.h` / `lib/duckdb.hpp`. Override the version with `DUCKDB_VERSION` if needed. Re-run after a version bump; the script replaces assets when the pinned version changes.

### Troubleshooting

| Issue | Action |
|-------|--------|
| `libduckdb.so` missing | Run `bash scripts/download-duckdb-linux.sh` |
| RIDE page not loading | Use `http:*:8888` in compose (not `http::8888`); check `docker compose -f docker/docker-compose.yml logs` |
| RIDE not required for tests | Run `bash scripts/run-tests-headless.sh` or `docker exec` into the container |
| Stale code after edits | `]link.refresh duck` |
| Port 8888 in use | Stop other services or change port mapping in `docker/docker-compose.yml` |
