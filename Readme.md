# duckdb-dyalog

Dyalog APL bindings for [DuckDB](https://duckdb.org/) via the C API (`⎕NA`). Query in-memory or on-disk databases, run parameterized SQL, bulk-load columns with the chunk appender, and use advanced features (prepared statements, Arrow, pending execution) exposed as APL functions under a linked namespace.

## Documentation

| Resource | Purpose |
|----------|---------|
| **[docs/getting-started.md](docs/getting-started.md)** | Step-by-step setup and usage examples |
| **[demo.txt](demo.txt)** | Full paste-in session (parquet, bulk `append`, copy-out) |
| **[duckdb-dyalog.ipynb](duckdb-dyalog.ipynb)** | Jupyter notebook walkthrough |
| **[CLAUDE.md](CLAUDE.md)** | Contributor / agent notes: architecture, APL file rules, testing |

## Requirements

- **Dyalog APL** with [Link](https://github.com/Dyalog/link) (`]link`) and `⎕NA` FFI
- **DuckDB** shared library in `lib/` (see [Platform libraries](#platform-libraries))
- On **Windows**, OpenSSL DLLs may be required for some DuckDB extensions (see below)

## Quick start

From the repository root, adjust `root` to your clone path, then in a Dyalog session:

```apl
root←'/path/to/duckdb-dyalog/'   ⍝ trailing slash; Windows: 'c:/path/to/duckdb-dyalog/'
]link.create duck root
duck.db.init root,'lib/'

_db←duck.db.open ':memory:'
_con←duck.db.connect _db
duck.db.toTable duck.db.query _con 'SELECT 42 AS answer'
⍝ … work …
{}duck.db.disconnect _con
{}duck.db.close _db
```

Always call **`duck.db.init`** with the directory that contains `duckdb.dll` / `libduckdb.so` / `libduckdb.dylib` **before** other `duck.db.*` calls (unless your workflow already initialized the namespace).

More patterns (parameters, bulk insert, NULLs) are in **[docs/getting-started.md](docs/getting-started.md)**.

## Running tests

Tests live under `db/tests/` and are run through **`duck.db.runAllTests`**.

**Option A — Dyalog script (from repo root)**

```text
dyascript.exe run_tests.apls
```

**Option B — PowerShell helper**

```powershell
.\scripts\run-tests.ps1
```

The script links the `duck` namespace to the current directory, runs `duck.db.init` on `lib/`, then `duck.db.runAllTests`. Override the executable with `DUCKDB_DYALOG_SCRIPT` if `dyascript.exe` is not on `PATH`.

## Platform libraries

| OS | Expected file under `lib/` |
|----|----------------------------|
| Windows | `duckdb.dll` |
| Linux | `libduckdb.so` |
| macOS | `libduckdb.dylib` (must match the name expected by `db/init` for your build) |

Dyalog’s own runtime (`dyalog64.dll` / `dyalog64.so`) is used for low-level memory helpers (`read` / `write` namespaces).

**Windows OpenSSL:** some DuckDB builds expect OpenSSL 3.x DLLs (e.g. `libcrypto-3-x64.dll`, `libssl-3-x64.dll`) next to `duckdb.dll` or on `PATH`. If HTTPS or an extension fails to load, check DuckDB’s release notes for your version.

## Repository layout (high level)

- `db/` — linked as `duck.db`: `init`, `open`, `query`, `append`, prepared/appender helpers, `api` (`⎕NA` map), `read` / `write`, `type`, tests under `db/tests/`
- `lib/` — place vendor DuckDB binaries here (not always committed)
- `run_tests.apls` — non-interactive test driver
- `scripts/` — CI-friendly wrappers

## Roadmap / internal notes

Maintainer-focused plans and binding notes: **[docs/dev/](docs/dev/)** (see [docs/dev/README.md](docs/dev/README.md)).

## License

See [LICENSE](LICENSE) in the repository root.
