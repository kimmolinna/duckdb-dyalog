#ifndef DUCKDB_ARROW_EXPORT_H
#define DUCKDB_ARROW_EXPORT_H

#include <stdint.h>

#include "duckdb.h"

#ifdef __cplusplus
extern "C" {
#endif

// Export query results to an Arrow IPC stream file (.arrows).
// error_out, when non-NULL, receives a duckdb_malloc'd message (caller frees with duckdb_free).
DUCKDB_C_API duckdb_state duckdb_export_query_arrow_ipc(duckdb_connection connection, const char *sql,
                                                        const char *path, uint64_t *rows_written,
                                                        char **error_out);

// Export query results to an Arrow IPC stream in memory.
// out_data receives duckdb_malloc'd bytes (caller frees with duckdb_free).
DUCKDB_C_API duckdb_state duckdb_export_query_arrow_ipc_buffer(duckdb_connection connection,
                                                               const char *sql, uint64_t *rows_written,
                                                               uint8_t **out_data, uint64_t *out_size,
                                                               char **error_out);

#ifdef __cplusplus
}
#endif

#endif
