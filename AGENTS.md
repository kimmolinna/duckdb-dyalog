# duckdb-dyalog

Dyalog APL bindings for DuckDB via the C API.

## Cursor Cloud specific instructions

This repository supports automated APL testing in [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent) using Dyalog 20 in Docker with RIDE over TCP (Zero Footprint HTTP).

### Environment

Cloud agent configuration lives in [`.cursor/environment.json`](.cursor/environment.json):

- Builds a Ubuntu image with Docker-in-Docker (see [`.cursor/Dockerfile`](.cursor/Dockerfile))
- Runs [`.cursor/install.sh`](.cursor/install.sh) on each agent boot (pulls Dyalog, downloads DuckDB, prints verify output)
- Starts Dyalog+RIDE via [`scripts/cloud-agent-up.sh`](scripts/cloud-agent-up.sh) (`--force-recreate` so compose changes apply)

### Syncing local changes to Cloud Agent

Local Cursor edits **do not** automatically appear in the Cloud Agent window or dashboard environment UI. Three separate layers exist:

| Layer | What it is | How it updates |
|-------|------------|----------------|
| Local IDE | Your machine | Save files, `git commit`, `git push` |
| Git remote | Source of truth for the agent | `git push origin master` |
| Cloud Agent VM | Isolated Ubuntu machine | **New agent run** from the pushed commit |
| Dashboard environment | Cached Docker image / snapshot | Rebuild when `.cursor/Dockerfile` changes |

**After changing `.cursor/*`, `docker/*`, `scripts/*`, or `AGENTS.md`:**

1. Commit and push to GitHub.
2. Open [Cloud Agents dashboard → Environments](https://cursor.com/dashboard/cloud-agents#environments).
3. If you changed `.cursor/Dockerfile`, trigger an **environment rebuild** (or create a new environment version). Dockerfile layers are cached; editing `install.sh` alone does not rebuild the base image.
4. Start a **new** Cloud Agent (do not resume an old run) on branch `master` at the latest commit.
5. In the agent, run `bash scripts/cloud-agent-verify.sh` and confirm the commit hash and `RIDE_INIT=http:*:8888`.

Cursor reads [`.cursor/environment.json`](.cursor/environment.json) from the **commit the agent starts on** (highest priority over dashboard defaults). The dashboard setup screen may still show an older snapshot until you rebuild — that is normal; trust the verify script inside a fresh agent run.

**APL code changes** inside an already-running Dyalog session: `]link.refresh duck` (Link does not watch files on Linux).

**Dyalog/Docker config changes** (e.g. `RIDE_INIT`): restart the compose stack — `bash scripts/cloud-agent-up.sh` or start a new agent (terminal runs recreate automatically).

### Syncing Cloud Agent changes back to local

Cloud Agent changes **do not** appear in your local Cursor workspace automatically. The agent runs on an isolated VM, commits to a **separate branch** on GitHub, and hands off via git — the same as a colleague’s PR.

**Recommended agent handoff:** At the end of a Cloud Agent task, ask it to **commit, push, and open a PR** (or report the branch name). Without a push, changes stay on the cloud VM only.

#### If the agent opened a PR

1. Open the PR link from the agent run or from GitHub (`kimmolinna/duckdb-dyalog`).
2. Review and merge the PR.
3. Locally:

```bash
git checkout master
git pull origin master
```

4. In Dyalog (if using Link):

```apl
]link.refresh duck
```

#### If the agent pushed a branch without a PR

Find the branch name on the agent page or on GitHub, then:

```bash
git fetch origin
git checkout <branch-name>
git pull origin <branch-name>
```

To merge into `master`:

```bash
git checkout master
git merge origin/<branch-name>
```

#### If nothing appears on GitHub

The agent may not have committed or pushed. Send a follow-up: *“Commit all changes, push to a branch, and open a PR.”* Use the agent’s **Files changed** / conversation view to confirm work was done.

#### Optional: changes on your machine directly

[My Machines](https://cursor.com/docs/cloud-agent/my-machines) runs agent tool calls on your laptop (same repo checkout), so file edits land locally without a PR. That is different from the default cloud VM setup used by this repo’s `.cursor/environment.json`.

| Direction | How |
|-----------|-----|
| Local → Cloud Agent | `git push`, then start a **new** agent on that commit |
| Cloud Agent → Local | PR or branch on GitHub → **`git pull`** locally |
| Cloud VM only (no pull) | Remote desktop in the agent UI — test there, changes not local |

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

### Linux C shim (`libduckdb_shim.so`)

On Linux x86_64, Dyalog 20's `⎕NA` segfaults when calling DuckDB C functions that take `duckdb_result` by value (a 48-byte struct). A small C shim library wraps these as pointer-accepting functions. The shim source is [`lib/duckdb_shim.c`](lib/duckdb_shim.c) and must be compiled before running:

```bash
gcc -shared -fPIC -o lib/libduckdb_shim.so lib/duckdb_shim.c -Llib -lduckdb -Wl,-rpath,lib
```

The `LD_LIBRARY_PATH=/workspace/lib` env var is set in `docker-compose.yml` and `run-tests-headless.sh` so the shim can find `libduckdb.so` at runtime. If you add new DuckDB API calls that take `duckdb_result` by value, add corresponding `_ptr` wrappers to the shim.

### Troubleshooting

| Issue | Action |
|-------|--------|
| `libduckdb.so` missing | Run `bash scripts/download-duckdb-linux.sh` |
| `libduckdb_shim.so` missing | Compile: `gcc -shared -fPIC -o lib/libduckdb_shim.so lib/duckdb_shim.c -Llib -lduckdb` |
| RIDE page not loading | Use `http:*:8888` in compose (not `http::8888`); check `docker compose -f docker/docker-compose.yml logs` |
| RIDE not required for tests | Run `bash scripts/run-tests-headless.sh` or `docker exec` into the container |
| Stale code after edits | `]link.refresh duck` |
| Port 8888 in use | Stop other services or change port mapping in `docker/docker-compose.yml` |
