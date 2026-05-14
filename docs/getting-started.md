# Getting started with duckdb-dyalog

This guide assumes you have cloned the repository and obtained a **DuckDB** dynamic library compatible with your OS (see [Readme.md](../Readme.md#platform-libraries)).

## 1. Link the namespace

Use an absolute path to the repo root with a **trailing slash** (works the same on Windows with forward slashes):

```apl
root←'/absolute/path/to/duckdb-dyalog/'
]link.create duck root
```

The application code lives in namespace **`duck.db`** (folder `db/`).

## 2. Initialize FFI and helpers

Pass the directory that contains the DuckDB binary (typically `lib/` inside the repo):

```apl
duck.db.init root,'lib/'
```

This sets up:

- `api` — `⎕NA` bindings to DuckDB C functions  
- `read` / `write` — memory helpers for typed I/O  
- `type` — DuckDB type constants (e.g. `duck.db.type.INTEGER`)

You normally call **`init` once** per workspace session.

## 3. Open a database and a connection

### In-memory

```apl
_db←duck.db.open ':memory:'
_con←duck.db.connect _db
```

### File on disk

```apl
_db←duck.db.open '/path/to/file.duckdb'
_con←duck.db.connect _db
```

`open` returns a database handle; `connect` returns a connection handle used by `query`, `prepareQuery`, `append`, etc.

## 4. Run SQL and show results

`query` returns a structured value (column metadata and arrays). `toTable` formats it for display:

```apl
duck.db.toTable duck.db.query _con 'SELECT version() AS v'
```

## 5. Parameterized queries (recommended)

Use **`queryParams`** for a single-shot prepare → bind → execute → cleanup flow with positional parameters `$1`, `$2`, …:

```apl
duck.db.toTable duck.db.queryParams _con 'SELECT $1 AS twice' (,21)
```

`⎕NULL` in the parameter vector binds SQL NULL (see below).

For manual control (reuse one prepared statement, inspect metadata), use `prepareQuery`, `bindParams`, `executePrepared`, and `destroyPrepared` as documented in [CLAUDE.md](../CLAUDE.md).

## 6. Bulk insert with `append`

Define a table, then pass column data as nested vectors and a matching list of DuckDB type codes:

```apl
duck.db.query _con 'CREATE TABLE demo (a INTEGER, b DOUBLE)'
a←⍳100
b←100⍴0.5
duck.db.append _con '' 'demo' (a b) (duck.db.type.INTEGER duck.db.type.DOUBLE)
duck.db.toTable duck.db.query _con 'SELECT * FROM demo LIMIT 5'
```

Details (batching, validity / NULL masks) follow the same rules as the implementation and tests in `db/tests/`.

## 7. NULL values

SQL NULL is represented by **`⎕NULL`** in parameter binding and in result columns when reading chunks.

Example insert:

```apl
duck.db.query _con 'CREATE TABLE nulldemo (id INTEGER, name VARCHAR)'
{}duck.db.queryParams _con 'INSERT INTO nulldemo VALUES ($1, $2)' (1 ⎕NULL)
duck.db.toTable duck.db.query _con 'SELECT * FROM nulldemo'
```

## 8. Close cleanly

Always release connection and database handles when finished:

```apl
{}duck.db.disconnect _con
{}duck.db.close _db
```

Discard functions that return no meaningful result are often invoked with `{}` so the session stays tidy.

## 9. Longer examples

- **[demo.txt](../demo.txt)** — end-to-end script: parquet paths, million-row `append`, `COPY … PARQUET`  
- **`duck.db.tests.*`** — executable API usage in test tradfns under `db/tests/`

## 10. Running the test suite

After **`]link.create`** and **`duck.db.init`** (as in section 1), run the full suite in the session:

```apl
duck.db.runAllTests
```

Individual tradfns such as **`duck.db.tests.test`** or **`duck.db.tests.testPhase1`** can be called directly; the unified list is in **`db/runAllTests.aplf`**. See also [Readme.md — Running tests](../Readme.md#running-tests).

## 11. Session settings

`duck.db.init` sets session globals used by the library (e.g. `⎕IO←0`, `⎕ML←1`, decimal float). If you rely on different `⎕IO` in your own code, call `duck.db` functions with awareness of index origin in *your* arrays vs what the library expects.

## Next topics (not duplicated here)

Row-wise **appender** APIs, **pending** execution, **Arrow** conversion, configuration (`config` / `openExt`), and error helpers are covered in [CLAUDE.md](../CLAUDE.md) and exercised in `db/tests/testPhase2.aplf` and related batches.
