#include <stdio.h>
#include <stdlib.h>

#include "duckdb.h"
#include "duckdb_arrow_export.h"

int main(int argc, char **argv) {
	const char *out_path = argc > 1 ? argv[1] : "/tmp/duckdb-dyalog-test.arrows";

	duckdb_database db = NULL;
	if (duckdb_open(NULL, &db) == DuckDBError) {
		fprintf(stderr, "duckdb_open failed\n");
		return 1;
	}

	duckdb_connection con = NULL;
	if (duckdb_connect(db, &con) == DuckDBError) {
		fprintf(stderr, "duckdb_connect failed\n");
		duckdb_close(&db);
		return 1;
	}

	const char *sql = "SELECT i AS value, i * 1.5 AS scaled FROM range(1000) t(i)";
	uint64_t rows = 0;
	char *error = NULL;

	duckdb_state st = duckdb_export_query_arrow_ipc(con, sql, out_path, &rows, &error);
	if (st != DuckDBSuccess) {
		fprintf(stderr, "export failed: %s\n", error != NULL ? error : "unknown error");
		if (error != NULL) {
			duckdb_free(error);
		}
		duckdb_disconnect(&con);
		duckdb_close(&db);
		return 1;
	}

	printf("Exported %llu rows to %s\n", (unsigned long long)rows, out_path);

	/* Buffer export smoke test */
	uint8_t *buffer = NULL;
	uint64_t size = 0;
	st = duckdb_export_query_arrow_ipc_buffer(con, sql, &rows, &buffer, &size, &error);
	if (st != DuckDBSuccess) {
		fprintf(stderr, "buffer export failed: %s\n", error != NULL ? error : "unknown error");
		if (error != NULL) {
			duckdb_free(error);
		}
		duckdb_disconnect(&con);
		duckdb_close(&db);
		return 1;
	}
	printf("Buffer export OK: %llu bytes, %llu rows\n", (unsigned long long)size, (unsigned long long)rows);
	if (buffer != NULL) {
		duckdb_free(buffer);
	}

	if (error != NULL) {
		duckdb_free(error);
	}
	duckdb_disconnect(&con);
	duckdb_close(&db);
	return 0;
}
