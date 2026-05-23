#include <stdint.h>
#include <stddef.h>

typedef uint64_t idx_t;
typedef int32_t duckdb_state;
typedef void *duckdb_data_chunk;

typedef enum { DUCKDB_RESULT_TYPE_INVALID = 0 } duckdb_result_type;
typedef enum { DUCKDB_STATEMENT_TYPE_INVALID = 0 } duckdb_statement_type;

typedef struct {
    idx_t deprecated_column_count;
    idx_t deprecated_row_count;
    idx_t deprecated_rows_changed;
    void *deprecated_columns;
    char *deprecated_error_message;
    void *internal_data;
} duckdb_result;

extern duckdb_data_chunk duckdb_fetch_chunk(duckdb_result result);
extern duckdb_statement_type duckdb_result_statement_type(duckdb_result result);
extern duckdb_result_type duckdb_result_return_type(duckdb_result result);

duckdb_data_chunk duckdb_fetch_chunk_ptr(duckdb_result *result) {
    return duckdb_fetch_chunk(*result);
}

int32_t duckdb_result_statement_type_ptr(duckdb_result *result) {
    return (int32_t)duckdb_result_statement_type(*result);
}

int32_t duckdb_result_return_type_ptr(duckdb_result *result) {
    return (int32_t)duckdb_result_return_type(*result);
}
