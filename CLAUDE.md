# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DuckDB interface for Dyalog APL, providing native bindings to the DuckDB C API. The project enables APL users to interact with DuckDB databases through FFI (Foreign Function Interface) using Dyalog's `⎕NA` system.

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
- `read`: Provides functions to read C data types from memory (i8, i16, i32, i64, u8, u16, u32, u64, float, double, interval, string, hint, utf8)
- `write`: Provides functions to write APL arrays to C memory (same data types)
- Both initialized during `db.init`

**Type System (`db/type.apln`)**
- Namespace containing DuckDB type constants (INTEGER=4, BIGINT=5, VARCHAR=17, TIMESTAMP=12, etc.)
- Matches the DUCKDB_TYPE enum from duckdb.h

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
- `readChunk.aplf`: Internal function to read data chunks with type-specific deserialization
- `append.aplf`: Bulk insert data using DuckDB's appender API with data chunk batching
- `toTable.aplf`: Formats query results as a table (transpose with column headers)
- `toJson.aplf`: Converts results to JSON format

*Testing:*
- `test.aplf`: Comprehensive test suite for C API functionality
- `testPhase1.aplf`: Tests for prepared statements, configuration, error handling, and parameter binding

### Data Flow

1. **Initialization**: `db.init 'lib/'` sets up all FFI bindings and initializes memory I/O
2. **Query Execution**: `query` uses result chunks API, iterating through chunks and calling `readChunk` per column
3. **Data Insertion**: `append` validates table schema, creates data chunks, writes APL arrays to memory, handles NULL values via validity masks, and batches by STANDARD_VECTOR_SIZE (2048 rows)

### Key Implementation Details

**Null Handling**
- APL's `⎕NULL` is used to represent SQL NULL
- Validity bitmasks track NULL values when reading/writing
- `readChunk` checks validity pointers and applies nullmask to replace values with `⎕NULL`

**Type Conversions**
- TIMESTAMP: APL timestamps converted to/from DuckDB microseconds with `ts_corr` offset (line 4 in init.aplf)
- VARCHAR: Handles both short strings (≤12 bytes, inline) and long strings (>12 bytes, pointer-based)
- INTERVAL: Converted to APL format as (months days hours minutes seconds microseconds)
- Float/Double: Special handling for validity bitmasks using floating-point representation parsing

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

**Session Settings**
- `⎕FR←1287`: Decimal floating point (128-bit)
- `⎕ML←1`: Migration level 1
- `⎕IO←0`: Index origin 0
- `⎕PP←34`: Print precision 34

## Development Workflow

### Testing

Run the test suite:
```apl
]link.create duck /path/to/duckdb-dyalog
duck.db.test
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
- Platform detection via `⎕WG'APLVersion'` check for 'Linux' in init.aplf:8

## Dependencies

- **DuckDB C library** (lib/duckdb.dll or lib/libduckdb.so): Core database engine
- **Dyalog APL runtime**: dyalog64.dll/so for MEMCPY operations
- **OpenSSL libraries** (Windows): libcrypto-3-x64.dll, libssl-3-x64.dll for HTTPS extensions

## File Extensions

- `.aplf`: APL function (dfn or tradfn)
- `.apln`: APL namespace
- `.dyalog`: Legacy format (old/DuckDB.dyalog is previous implementation)
- `.ipynb`: Jupyter notebook with APL kernel for interactive examples
