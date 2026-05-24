#define NANOARROW_NAMESPACE DuckDbDyalog

#include "duckdb_arrow_export.h"

#include <stdio.h>
#include <string.h>

#include "nanoarrow/nanoarrow_ipc.h"

typedef struct {
	duckdb_result result;
	duckdb_arrow_options arrow_opts;
	duckdb_logical_type *types;
	const char **names;
	idx_t column_count;
	struct ArrowSchema schema;
} export_context;

static void clear_error(char **error_out) {
	if (error_out == NULL || *error_out == NULL) {
		return;
	}
	duckdb_free(*error_out);
	*error_out = NULL;
}

static void set_error(char **error_out, const char *message) {
	if (error_out == NULL || message == NULL) {
		return;
	}
	clear_error(error_out);
	size_t length = strlen(message) + 1;
	char *copy = (char *)duckdb_malloc(length);
	if (copy != NULL) {
		memcpy(copy, message, length);
		*error_out = copy;
	}
}

static void set_error_from_error_data(char **error_out, duckdb_error_data error_data) {
	if (error_data == NULL || !duckdb_error_data_has_error(error_data)) {
		return;
	}
	const char *message = duckdb_error_data_message(error_data);
	set_error(error_out, message != NULL ? message : "DuckDB Arrow conversion failed");
}

static void set_error_from_arrow(char **error_out, struct ArrowError *arrow_error) {
	if (error_out == NULL || arrow_error == NULL) {
		return;
	}
	const char *message = ArrowErrorMessage(arrow_error);
	if (message != NULL && message[0] != '\0') {
		set_error(error_out, message);
	} else {
		set_error(error_out, "Arrow IPC write failed");
	}
}

static void release_schema(struct ArrowSchema *schema) {
	if (schema != NULL && schema->release != NULL) {
		schema->release(schema);
	}
	memset(schema, 0, sizeof(*schema));
}

static void release_array(struct ArrowArray *array) {
	if (array != NULL && array->release != NULL) {
		array->release(array);
	}
	memset(array, 0, sizeof(*array));
}

static void export_context_cleanup(export_context *ctx) {
	if (ctx == NULL) {
		return;
	}
	release_schema(&ctx->schema);
	if (ctx->types != NULL) {
		for (idx_t column = 0; column < ctx->column_count; column++) {
			duckdb_destroy_logical_type(&ctx->types[column]);
		}
		duckdb_free(ctx->types);
		ctx->types = NULL;
	}
	if (ctx->names != NULL) {
		duckdb_free(ctx->names);
		ctx->names = NULL;
	}
	if (ctx->arrow_opts != NULL) {
		duckdb_destroy_arrow_options(&ctx->arrow_opts);
		ctx->arrow_opts = NULL;
	}
	duckdb_destroy_result(&ctx->result);
	memset(ctx, 0, sizeof(*ctx));
}

static duckdb_state export_context_init(export_context *ctx, duckdb_connection connection, const char *sql,
                                        char **error_out) {
	memset(ctx, 0, sizeof(*ctx));

	if (connection == NULL) {
		set_error(error_out, "Connection is NULL");
		return DuckDBError;
	}
	if (sql == NULL) {
		set_error(error_out, "SQL is required");
		return DuckDBError;
	}

	duckdb_state query_state = duckdb_query(connection, sql, &ctx->result);
	if (query_state != DuckDBSuccess) {
		set_error(error_out, duckdb_result_error(&ctx->result));
		duckdb_destroy_result(&ctx->result);
		return DuckDBError;
	}

	ctx->column_count = duckdb_column_count(&ctx->result);
	if (ctx->column_count == 0) {
		set_error(error_out, "Query returned no columns (not a SELECT result?)");
		export_context_cleanup(ctx);
		return DuckDBError;
	}

	duckdb_connection_get_arrow_options(connection, &ctx->arrow_opts);

	ctx->types = (duckdb_logical_type *)duckdb_malloc(sizeof(duckdb_logical_type) * ctx->column_count);
	ctx->names = (const char **)duckdb_malloc(sizeof(const char *) * ctx->column_count);
	if (ctx->types == NULL || ctx->names == NULL) {
		set_error(error_out, "Out of memory allocating column metadata");
		export_context_cleanup(ctx);
		return DuckDBError;
	}

	for (idx_t column = 0; column < ctx->column_count; column++) {
		ctx->types[column] = duckdb_column_logical_type(&ctx->result, column);
		ctx->names[column] = duckdb_column_name(&ctx->result, column);
	}

	duckdb_error_data schema_error =
	    duckdb_to_arrow_schema(ctx->arrow_opts, ctx->types, ctx->names, ctx->column_count, &ctx->schema);
	if (schema_error != NULL && duckdb_error_data_has_error(schema_error)) {
		set_error_from_error_data(error_out, schema_error);
		duckdb_destroy_error_data(&schema_error);
		export_context_cleanup(ctx);
		return DuckDBError;
	}
	if (schema_error != NULL) {
		duckdb_destroy_error_data(&schema_error);
	}

	return DuckDBSuccess;
}

static duckdb_state export_context_write_chunks(export_context *ctx, struct ArrowIpcWriter *writer,
                                                struct ArrowError *ipc_error, uint64_t *rows_written,
                                                char **error_out) {
	struct ArrowArrayView array_view;
	memset(&array_view, 0, sizeof(array_view));
	if (ArrowArrayViewInitFromSchema(&array_view, &ctx->schema, ipc_error) != NANOARROW_OK) {
		set_error_from_arrow(error_out, ipc_error);
		return DuckDBError;
	}

	uint64_t rows = 0;
	duckdb_state export_state = DuckDBSuccess;

	while (1) {
		duckdb_data_chunk chunk = duckdb_fetch_chunk(ctx->result);
		if (chunk == NULL) {
			break;
		}

		rows += duckdb_data_chunk_get_size(chunk);

		struct ArrowArray array;
		memset(&array, 0, sizeof(array));
		duckdb_error_data chunk_error = duckdb_data_chunk_to_arrow(ctx->arrow_opts, chunk, &array);
		if (chunk_error != NULL && duckdb_error_data_has_error(chunk_error)) {
			set_error_from_error_data(error_out, chunk_error);
			export_state = DuckDBError;
			duckdb_destroy_error_data(&chunk_error);
			duckdb_destroy_data_chunk(&chunk);
			break;
		}
		if (chunk_error != NULL) {
			duckdb_destroy_error_data(&chunk_error);
		}

		ArrowArrayViewReset(&array_view);
		if (ArrowArrayViewInitFromSchema(&array_view, &ctx->schema, ipc_error) != NANOARROW_OK ||
		    ArrowArrayViewSetArray(&array_view, &array, ipc_error) != NANOARROW_OK ||
		    ArrowIpcWriterWriteArrayView(writer, &array_view, ipc_error) != NANOARROW_OK) {
			set_error_from_arrow(error_out, ipc_error);
			export_state = DuckDBError;
			release_array(&array);
			duckdb_destroy_data_chunk(&chunk);
			break;
		}

		release_array(&array);
		duckdb_destroy_data_chunk(&chunk);
	}

	if (export_state == DuckDBSuccess &&
	    ArrowIpcWriterWriteArrayView(writer, NULL, ipc_error) != NANOARROW_OK) {
		set_error_from_arrow(error_out, ipc_error);
		export_state = DuckDBError;
	}

	ArrowArrayViewReset(&array_view);

	if (export_state == DuckDBSuccess && rows_written != NULL) {
		*rows_written = rows;
	}
	return export_state;
}

static duckdb_state export_query_arrow_ipc_internal(duckdb_connection connection, const char *sql,
                                                    uint64_t *rows_written, char **error_out,
                                                    duckdb_state (*write_fn)(export_context *, struct ArrowError *,
                                                                             uint64_t *, char **, void *),
                                                    void *write_ctx) {
	if (rows_written != NULL) {
		*rows_written = 0;
	}
	clear_error(error_out);

	export_context ctx;
	duckdb_state init_state = export_context_init(&ctx, connection, sql, error_out);
	if (init_state != DuckDBSuccess) {
		return DuckDBError;
	}

	struct ArrowError ipc_error;
	ArrowErrorInit(&ipc_error);

	duckdb_state export_state = write_fn(&ctx, &ipc_error, rows_written, error_out, write_ctx);
	export_context_cleanup(&ctx);
	return export_state;
}

typedef struct {
	FILE *file;
	struct ArrowBuffer buffer;
	int use_buffer;
} export_sink;

static duckdb_state export_write_to_sink(export_context *ctx, struct ArrowError *ipc_error, uint64_t *rows_written,
                                         char **error_out, void *write_ctx_void) {
	export_sink *sink = (export_sink *)write_ctx_void;
	struct ArrowIpcOutputStream output_stream;
	memset(&output_stream, 0, sizeof(output_stream));

	if (sink->use_buffer) {
		ArrowBufferInit(&sink->buffer);
		if (ArrowIpcOutputStreamInitBuffer(&output_stream, &sink->buffer) != NANOARROW_OK) {
			set_error(error_out, "Failed to initialize Arrow IPC buffer stream");
			return DuckDBError;
		}
	} else {
		if (ArrowIpcOutputStreamInitFile(&output_stream, sink->file, /*close_on_release=*/1) != NANOARROW_OK) {
			set_error(error_out, "Failed to initialize Arrow IPC output stream");
			return DuckDBError;
		}
	}

	struct ArrowIpcWriter writer;
	memset(&writer, 0, sizeof(writer));
	if (ArrowIpcWriterInit(&writer, &output_stream) != NANOARROW_OK) {
		set_error(error_out, "Failed to initialize Arrow IPC writer");
		if (output_stream.release != NULL) {
			output_stream.release(&output_stream);
		}
		return DuckDBError;
	}

	if (ArrowIpcWriterWriteSchema(&writer, &ctx->schema, ipc_error) != NANOARROW_OK) {
		set_error_from_arrow(error_out, ipc_error);
		ArrowIpcWriterReset(&writer);
		return DuckDBError;
	}

	duckdb_state export_state = export_context_write_chunks(ctx, &writer, ipc_error, rows_written, error_out);
	ArrowIpcWriterReset(&writer);
	return export_state;
}

duckdb_state duckdb_export_query_arrow_ipc(duckdb_connection connection, const char *sql, const char *path,
                                           uint64_t *rows_written, char **error_out) {
	if (path == NULL) {
		set_error(error_out, "Output path is required");
		return DuckDBError;
	}

	FILE *file = fopen(path, "wb");
	if (file == NULL) {
		set_error(error_out, "Failed to open Arrow output file for writing");
		return DuckDBError;
	}

	export_sink sink;
	memset(&sink, 0, sizeof(sink));
	sink.file = file;
	sink.use_buffer = 0;

	return export_query_arrow_ipc_internal(connection, sql, rows_written, error_out, export_write_to_sink, &sink);
}

duckdb_state duckdb_export_query_arrow_ipc_buffer(duckdb_connection connection, const char *sql,
                                                uint64_t *rows_written, uint8_t **out_data, uint64_t *out_size,
                                                char **error_out) {
	if (out_data == NULL || out_size == NULL) {
		set_error(error_out, "Output buffer pointers are required");
		return DuckDBError;
	}
	*out_data = NULL;
	*out_size = 0;

	export_sink sink;
	memset(&sink, 0, sizeof(sink));
	sink.use_buffer = 1;

	duckdb_state export_state =
	    export_query_arrow_ipc_internal(connection, sql, rows_written, error_out, export_write_to_sink, &sink);
	if (export_state != DuckDBSuccess) {
		ArrowBufferReset(&sink.buffer);
		return DuckDBError;
	}

	if (sink.buffer.size_bytes == 0) {
		set_error(error_out, "Arrow export produced empty buffer");
		ArrowBufferReset(&sink.buffer);
		return DuckDBError;
	}

	uint8_t *copy = (uint8_t *)duckdb_malloc((size_t)sink.buffer.size_bytes);
	if (copy == NULL) {
		set_error(error_out, "Out of memory copying Arrow IPC buffer");
		ArrowBufferReset(&sink.buffer);
		return DuckDBError;
	}

	memcpy(copy, sink.buffer.data, (size_t)sink.buffer.size_bytes);
	*out_data = copy;
	*out_size = (uint64_t)sink.buffer.size_bytes;
	ArrowBufferReset(&sink.buffer);
	return DuckDBSuccess;
}
