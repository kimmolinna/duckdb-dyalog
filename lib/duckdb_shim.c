/*
 * Linux x86-64 ABI shim for duckdb_fetch_chunk.
 *
 * Dyalog APL 20 on Linux cannot pass the 48-byte duckdb_result struct
 * by value via ⎕NA. This thin wrapper accepts the struct by pointer
 * and forwards the by-value call to the real duckdb_fetch_chunk.
 *
 * Build:
 *   gcc -shared -fPIC -o libduckdb_shim.so duckdb_shim.c \
 *       -L. -lduckdb -Wl,-rpath,.
 */
#include <stdint.h>

typedef struct {
    uint64_t deprecated_column_count;
    uint64_t deprecated_row_count;
    uint64_t deprecated_rows_changed;
    void *deprecated_columns;
    char *deprecated_error_message;
    void *internal_data;
} duckdb_result;

typedef void *duckdb_data_chunk;

extern duckdb_data_chunk duckdb_fetch_chunk(duckdb_result result);

duckdb_data_chunk duckdb_fetch_chunk_ptr(duckdb_result *result) {
    return duckdb_fetch_chunk(*result);
}
