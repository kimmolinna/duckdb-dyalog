# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DuckDB interface for Dyalog APL, providing native bindings to the DuckDB C API. The project enables APL users to interact with DuckDB databases through FFI (Foreign Function Interface) using Dyalog's `⎕NA` system.

**User-facing documentation:** [Readme.md](Readme.md) (overview, test commands), [docs/getting-started.md](docs/getting-started.md) (examples), [demo.txt](demo.txt). Maintainer plans: [docs/dev/](docs/dev/).

## CRITICAL: APL Function Syntax Rules

**NEVER use control structures (`:If`, `:For`, `:Select`, etc.) inside dfns (dynamic functions using `{...}`)!**

- **Dfns (Dynamic Functions)**: Use `{...}` syntax
  - Can ONLY use guards (`:` operator) for conditional logic
  - Can ONLY use recursion for iteration
  - Example: `{0=⍵:⍬ ⋄ ⍵,∇ ⍵-1}`  ✓ Correct
  - Example: `{:If 0=⍵ ⋄ ⍬ ⋄ :Else ⋄ ⍵ ⋄ :EndIf}`  ✗ WRONG - will cause SYNTAX ERROR

- **Tradfns (Traditional Functions)**: Use `∇` or function header
  - CAN use control structures (`:If`, `:For`, `:Select`, etc.)
  - Header format: `result←FunctionName args;local1;local2`
  - Example: `∇r←Add(a b) ⋄ r←a+b ∇`  ✓ Correct
  - **CANNOT be nested** - each function must be in its own `.aplf` file or namespace
  - Example: Defining a function inside another function with `∇...∇`  ✗ WRONG - not supported

**When in doubt, use tradfns for any logic requiring control structures!**

**Each function must be in its own file - no nested function definitions!**

## Architecture

### Core Components

**API Layer (`db/api.apln`)**
- Initializes all DuckDB C API function bindings via `⎕NA`
- Called during `db.init` to set up FFI mappings to either `duckdb.dll` (Windows) or `libduckdb.so` (Linux)
- Maps 118+ DuckDB C functions including:
  - Database operations (open, close, connect, configuration)
  - Query execution (standard and prepared statements)
  - Result handling (metadata, value extraction, streaming)
  - Parameter binding (all DuckDB types)
  - Data chunks, vectors, appenders
  - Arrow integration
  - Error handling and interrupts

**Memory I/O Namespaces (`db/read.apln`, `db/write.apln`)**
- Use `MEMCPY` and `STRNCPY` from either `dyalog64.dll` or `dyalog64.so` for low-level memory operations
- `read`: Provides functions to read C data types from memory (i8, i16, i32, i64, u8, u16, u32, u64, float, double, interval, string, stringi, hint, decimal, utf8)
- `write`: Provides functions to write APL arrays to C memory (same data types)
- Both initialized during `db.init`
- `read.stringi` reads signed-byte string structs (for BLOB)
- `read.hint` reads hugeint (128-bit) pairs
- `read.decimal` reads raw 16-byte decimal blocks

**Type System (`db/type.apln`)**
- Namespace containing DuckDB type constants matching `DUCKDB_TYPE` enum from `duckdb.h`
- Covers types 0-33: INVALID through ARRAY
- Note: UNION=28 (not JSON), JSON is an alias for VARCHAR (17)
- BIT=29, TIME_TZ=30, TIMESTAMP_TZ=31, UHUGEINT=32, ARRAY=33

**Public API Functions**

*Core Database Operations:*
- `open.aplf`: Opens database connection (file path or ':memory:')
- `openExt.aplf`: Opens database with configuration options
- `connect.aplf`: Creates connection handle from database pointer
- `disconnect.aplf`: Closes connection handle
- `close.aplf`: Closes database
- `version.aplf`: Returns DuckDB library version string
- `interrupt.aplf`: Interrupts a running query on a connection

*Configuration:*
- `config.aplf`: Creates configuration object with name/value pairs
- `destroyConfig.aplf`: Destroys configuration object

*Query Execution:*
- `query.aplf`: Executes SQL and returns results as nested arrays (column names + data columns)
- `queryParams.aplf`: Convenience function for parameterized queries (prepare → bind → execute in one call)

*Prepared Statements:*
- `prepareQuery.aplf`: Prepares a SQL statement with parameters ($1, $2, etc.)
- `bindParams.aplf`: Binds APL values to prepared statement parameters (auto-detects types)
- `executePrepared.aplf`: Executes prepared statement and returns results
- `destroyPrepared.aplf`: Destroys prepared statement

*Data Operations:*
- `readVector.aplf`: Recursive function handling ALL DuckDB types — integers, floats, strings, timestamps, DECIMAL, BLOB, BIT, LIST, STRUCT, MAP, ARRAY, ENUM
- `readVectorSimple.aplf`: Helper for simple integer/unsigned types (0-9)
- `readChunks.aplf`: Internal streaming chunk reader using `duckdb_fetch_chunk`, delegates to `readVector`
- `readChunk.aplf`: Single-column chunk reader, delegates to `readVector` (backward compat)
- `readStringElements.aplf`: VARCHAR element reader with correct UTF-8 decoding
- `readListColumn.aplf`: LIST column reader using `readVector` for child elements
- `readStructColumn.aplf`: STRUCT column reader using `readVector` per field
- `readMapColumn.aplf`: MAP column reader (delegates to `readListColumn`)
- `readEnumColumn.aplf`: ENUM column reader
- `append.aplf`: Bulk insert data using DuckDB's appender API with data chunk batching, supports types 0-14 plus TIMESTAMP_S/MS/NS (20-22)
- `appenderBeginRow.aplf` / `appenderEndRow.aplf`: Row-wise appender row lifecycle
- `appenderFlush.aplf` / `appenderClose.aplf` / `appenderClear.aplf`: Row-wise appender buffer control
- `appenderAddColumn.aplf` / `appenderClearColumns.aplf`: Active column-list control for appenders
- `appenderError.aplf` / `appenderErrorData.aplf`: String and structured appender error retrieval
- `errorDataHasError.aplf` / `errorDataType.aplf` / `errorDataMessage.aplf` / `destroyErrorData.aplf`: Structured error-data helpers
- `toTable.aplf`: Formats query results as a table (transpose with column headers)
- `toShortTable.aplf`: Truncated table display (first/last 20 rows for large results)
- `toJson.aplf`: Converts results to JSON format
- `index.aplf`: Column/row selection by name or numeric index

*Testing (all under `db/tests/`):*
- `tests/test.aplf`: Comprehensive test suite for C API functionality
- `tests/testPhase1.aplf`: Tests for prepared statements, configuration, error handling, and parameter binding
- `tests/testPhase2.aplf`: Tests advanced types, pending/streaming execution, row-wise appender APIs, and structured appender errors
- `tests/testMergedTypes.aplf`: Tests DECIMAL, BLOB, BIT, HUGEINT, INTERVAL, ARRAY, NULL handling
- `tests/testTimestamps.aplf`: Tests all timestamp variants (S/MS/NS/TZ), DATE, TIME
- `tests/testUTF8.aplf`: Regression tests for UTF-8 bugs (short string read, append double-encoding)
- `tests/testAppendTypes.aplf`: Append+readback for various types, NULLs, large datasets
- `tests/testUtilities.aplf`: Tests toTable, toShortTable, index

### Data Flow

1. **Initialization**: `db.init 'lib/'` sets up all FFI bindings and initializes memory I/O
2. **Query Execution**: `query` uses streaming result chunks API via `duckdb_fetch_chunk`, calling `readVector` per column per chunk
3. **Data Insertion**: `append` validates table schema, creates data chunks, writes APL arrays to memory, handles NULL values via validity masks, and batches by STANDARD_VECTOR_SIZE (2048 rows)

### Recursive readVector Architecture

The `readVector` function is the core type dispatcher, handling ALL DuckDB types recursively:
- **Simple types (0-9)**: Delegated to `readVectorSimple` (integer/unsigned dispatch)
- **Float (10)**: IEEE 754 manual parsing when validity mask present, scoped `⎕FR←645`
- **Double (11)**: `645 ⎕DR⊃0 83 ⎕DR` for workspace-compaction safety, scoped `⎕FR←645`
- **Timestamps (12,20-22,31)**: Various `⎕DT` conversions with `ts_corr` offset
- **VARCHAR (17)**: UTF-8 decoding with `'UTF-8'⎕UCS` for both short (≤12 bytes) and long strings
- **BLOB (18) / BIT (29)**: Signed-byte string structs via `read.stringi`, BIT padding extraction
- **DECIMAL (19)**: Width/scale/internal_type dispatch, hugeint base-decode for large decimals
- **ENUM (23)**: Delegated to `readEnumColumn`
- **LIST (24), STRUCT (25), MAP (26), ARRAY (33)**: Recursive calls to `readVector` on child vectors
- **NULL masking**: Applied at end of each call level

### Key Implementation Details

**Null Handling**
- APL's `⎕NULL` is used to represent SQL NULL
- Validity bitmasks track NULL values when reading/writing
- `readChunk` checks validity pointers and applies nullmask to replace values with `⎕NULL`

**Type Conversions**
- TIMESTAMP: APL timestamps converted to/from DuckDB microseconds with `ts_corr` offset (line 4 in init.aplf)
- TIMESTAMP_S/MS/NS: Additional timestamp precision variants using appropriate `⎕DT` codes
- VARCHAR: Handles both short strings (≤12 bytes, inline) and long strings (>12 bytes, pointer-based). **Always uses `'UTF-8'⎕UCS` for decoding** — monadic `⎕UCS` breaks multi-byte sequences
- BLOB: Read via `read.stringi` (signed-byte string struct), returns raw byte vectors
- BIT: BLOB-like reading plus padding-bit extraction via `11 ⎕DR` and first-byte padding count
- DECIMAL: Gets width/scale/internal_type from logical type, reads via integer or hugeint path, scales by `10*-scale`
- INTERVAL: Converted to APL format as (months days hours minutes seconds microseconds)
- Float/Double: Special handling for validity bitmasks using floating-point representation parsing. Double uses `0 83 ⎕DR` before `645 ⎕DR` for workspace-compaction safety
- ARRAY: Fixed-size arrays partitioned from child vector

**Vector Size**
- STANDARD_VECTOR_SIZE is 2048 (updated from older versions)
- Data chunk operations process up to 2048 rows at a time

**Prepared Statements (Phase 1)**
- Full support for parameterized queries with automatic type detection
- Protects against SQL injection attacks
- Supports positional parameters ($1, $2, ...) and named parameters ($name)
- `bindParams` automatically detects APL data types and binds appropriately:
  - Booleans → `duckdb_bind_boolean`
  - Integers (based on magnitude) → `duckdb_bind_int32` or `duckdb_bind_int64`
  - Floats → `duckdb_bind_double`
  - Strings → `duckdb_bind_varchar`
  - `⎕NULL` → `duckdb_bind_null`
- Statement metadata available: parameter count, names, types, result column info

**Configuration Support (Phase 1)**
- Set database options before opening: threads, access mode, memory limits, etc.
- Use `config` to create configuration object, `openExt` to apply
- Example options: 'threads', 'access_mode', 'memory_limit', 'default_order'

**Error Handling (Phase 1)**
- `duckdb_result_error_type` provides structured error information
- Prepare errors caught with proper messages
- Query errors include table names and context

**Appender & ErrorData Extensions (Phase 2)**
- Row-wise appender flow supported (`begin_row`, typed append calls, `end_row`, `flush`, `close`, `clear`)
- Active appender column selection supported (`add_column`, `clear_columns`)
- Structured appender error retrieval supported via `duckdb_appender_error_data`
- Error-data helpers exposed (`duckdb_error_data_has_error`, `duckdb_error_data_error_type`, `duckdb_error_data_message`, `duckdb_destroy_error_data`)

**UTF-8 Handling Rules (Critical)**
- Sending strings to DuckDB API (open, query, prepare): use `<0UTF8[]` in `⎕NA` — runtime auto-encodes
- Sending strings with known byte-length (`duckdb_vector_assign_string_element_len`): use `<0U1[]` + manual `'UTF-8'⎕UCS` to avoid double-encoding
- Reading short VARCHAR (≤12 bytes): use `'UTF-8'⎕UCS` on raw bytes — **never** monadic `⎕UCS`
- Reading long VARCHAR (>12 bytes): use `'UTF-8'⎕UCS` via `read.utf8_l`

**Session Settings**
- `⎕FR←1287`: Decimal floating point (128-bit)
- `⎕ML←1`: Migration level 1
- `⎕IO←0`: Index origin 0
- `⎕PP←34`: Print precision 34

## Development Workflow

### Testing

Run the full suite in a Dyalog session after linking and **`duck.db.init`**: **`duck.db.runAllTests`**. Individual tradfns live under `duck.db.tests` (files in `db/tests/`), e.g. `duck.db.tests.testPhase1`. The list of suites is in **`db/runAllTests.aplf`**.

```apl
]link.create duck /path/to/duckdb-dyalog
duck.db.init '/path/to/duckdb-dyalog/lib/'
duck.db.runAllTests
```

The test suite validates:
- Logical type creation and destruction
- Data chunk API operations
- Appender functionality
- NULL value handling
- Vector data access

### Common Operations

**Basic query workflow:**
```apl
db.init 'lib/'
_db ← db.open ':memory:'
_con ← db.connect _db
result ← db.query _con 'SELECT * FROM table'
db.toTable result    ⍝ Format as table
db.disconnect _con
db.close _db
```

**Parameterized queries (SQL injection safe):**
```apl
⍝ One-liner convenience function
result ← db.queryParams _con 'SELECT * FROM users WHERE age > $1' (,25)

⍝ Or with manual control
stmt ← db.prepareQuery _con 'INSERT INTO users VALUES ($1, $2, $3)'
{}db.bindParams stmt (1 'Alice' 30)
result ← db.executePrepared stmt
{}db.destroyPrepared stmt
```

**Database with configuration:**
```apl
cfg ← db.config (⊂'threads' '4'),⊂'access_mode' 'READ_ONLY'
_db ← db.openExt '/path/to/database.db' cfg
_con ← db.connect _db
⍝ ... use connection ...
{}db.disconnect _con
{}db.close _db
{}db.destroyConfig cfg
```

**Bulk insert workflow:**
```apl
db.query _con 'CREATE TABLE test (a INT, b DOUBLE)'
data ← (⍳1000000) (1000000⍴0.5)  ⍝ Two columns
types ← (db.type.INTEGER) (db.type.DOUBLE)
db.append _con '' 'test' data types
```

**Handling NULL values:**
```apl
⍝ NULL is represented by ⎕NULL
{}db.queryParams _con 'INSERT INTO users VALUES ($1, $2)' (1 ⎕NULL)
result ← db.query _con 'SELECT * FROM users WHERE name IS NULL'
```

## Platform Differences

- Windows: Uses `duckdb.dll` and `dyalog64.dll` (requires libcrypto-3-x64.dll, libssl-3-x64.dll)
- Linux: Uses `libduckdb.so` and `dyalog64.so`
- macOS: Uses `libduckdb.dylib` and `dyalog64.dylib/so` depending on Dyalog runtime packaging
- Platform detection via `⎕WG'APLVersion'` check for 'Linux' in init.aplf:8

## Dependencies

- **DuckDB C library** (lib/duckdb.dll, lib/libduckdb.so, or lib/libduckdb.dylib): Core database engine
- **Dyalog APL runtime**: dyalog64.dll/so for MEMCPY operations
- **OpenSSL libraries** (Windows): libcrypto-3-x64.dll, libssl-3-x64.dll for HTTPS extensions

## File Extensions

- `.aplf`: APL function (dfn or tradfn)
- `.apln`: APL namespace
- `.dyalog`: Legacy single-file / workspace bundle format (older Dyalog workflows)
