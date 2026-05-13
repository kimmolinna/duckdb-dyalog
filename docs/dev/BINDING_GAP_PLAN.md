# DuckDB Binding Gap Audit and Delivery Plan

This file tracks what is still missing between `lib/duckdb.h` and `db/api.apln`,
and proposes a practical implementation order for Dyalog users.

## Current Audit Snapshot

- Header symbols found: `547`
- Bound in `db/api.apln`: `145`
- Missing bindings: `401` (after excluding non-function `duckdb_type`)

Raw machine-generated diff is stored in `audit_duckdb_bindings.json`.

## What Is "Necessary" for Dyalog First

Not all C API symbols are needed for a practical Dyalog package. Prioritize:

1. Stable runtime API used by application code (querying, prepared statements, appender, result metadata, type/value conversion).
2. Operational controls (pending/streaming execution, cancellation, progress, diagnostics).
3. Complex type ergonomics needed by users (decimal/date-time/list/struct/map/array).

Defer extension-authoring APIs (custom scalar/table/copy/cast functions, catalog internals, filesystem internals) unless needed.

## Priority Backlog

## P0 - Runtime Completeness (next)

These unblock common application use-cases with minimal surface-area risk:

- Streaming and pending:
  - `duckdb_pending_prepared`
  - `duckdb_pending_prepared_streaming`
  - `duckdb_pending_execute_task`
  - `duckdb_pending_execution_is_finished`
  - `duckdb_pending_error`
  - `duckdb_execute_prepared_streaming`
  - `duckdb_stream_fetch_chunk`
  - `duckdb_fetch_chunk`
  - `duckdb_destroy_pending`
- Result/statement ergonomics:
  - `duckdb_prepared_arrow_schema`
  - `duckdb_result_get_arrow_options`
  - `duckdb_result_arrow_array`
- Appender row-wise API:
  - `duckdb_appender_begin_row`
  - `duckdb_appender_end_row`
  - `duckdb_appender_flush`
  - `duckdb_appender_close`
  - `duckdb_appender_error`
  - `duckdb_appender_clear`

## P1 - Type and Value Coverage

Needed to make nested and richer SQL types first-class in APL:

- Decimal helpers:
  - `duckdb_create_decimal_type`
  - `duckdb_decimal_width`
  - `duckdb_decimal_scale`
  - `duckdb_decimal_internal_type`
  - `duckdb_decimal_to_double`
  - `duckdb_double_to_decimal`
- Date/time conversion helpers:
  - `duckdb_from_date`, `duckdb_to_date`
  - `duckdb_from_time`, `duckdb_to_time`
  - `duckdb_from_timestamp`, `duckdb_to_timestamp`
  - `duckdb_is_finite_date`
  - `duckdb_is_finite_timestamp`
- Nested type/vector helpers:
  - `duckdb_array_type_child_type`
  - `duckdb_array_type_array_size`
  - `duckdb_array_vector_get_child`
  - `duckdb_union_type_member_count`
  - `duckdb_union_type_member_name`
  - `duckdb_union_type_member_type`
  - `duckdb_selection_vector_get_data_ptr`
  - `duckdb_slice_vector`
  - `duckdb_vector_copy_sel`
  - `duckdb_vector_reference_vector`

## P2 - Value Object API

Needed for a generic "DuckDB value" abstraction in Dyalog wrappers:

- Constructors:
  - `duckdb_create_null_value`
  - `duckdb_create_bool`
  - `duckdb_create_int64`
  - `duckdb_create_double`
  - `duckdb_create_varchar`
  - `duckdb_create_blob`
  - `duckdb_create_date`
  - `duckdb_create_time`
  - `duckdb_create_timestamp`
  - `duckdb_create_interval`
  - `duckdb_create_list_value`
  - `duckdb_create_struct_value`
  - `duckdb_create_map_value`
  - `duckdb_create_array_value`
  - `duckdb_destroy_value`
- Accessors:
  - `duckdb_get_value_type`
  - `duckdb_is_null_value`
  - `duckdb_get_bool`
  - `duckdb_get_int64`
  - `duckdb_get_double`
  - `duckdb_get_varchar`
  - `duckdb_get_blob`
  - `duckdb_get_date`
  - `duckdb_get_time`
  - `duckdb_get_timestamp`
  - `duckdb_get_interval`
  - `duckdb_value_to_string`

## Deferred (Explicitly Non-Goals for now)

Implement only when there is a concrete Dyalog requirement:

- Custom function registration APIs (`duckdb_create_scalar_function`, `duckdb_register_scalar_function`, table/copy/aggregate/cast families).
- Catalog and client-context introspection (`duckdb_catalog_*`, `duckdb_client_context_*`).
- Filesystem internals (`duckdb_file_*`, `duckdb_file_system_*`, `duckdb_log_storage_*`).

## Delivery Strategy

1. Add `api.apln` bindings in small batches (10-20 functions each).
2. Add thin wrappers in separate `.aplf` files (one function per file).
3. Add tests in `db/testPhase2.aplf` for each batch (success + null/error paths).
4. Keep `db/query.aplf` and `db/append.aplf` backward-compatible.
5. Re-run audit script after each batch and track remaining diff.

## Next Implementation Slice (recommended immediate)

Batch A:
- `duckdb_pending_prepared`
- `duckdb_pending_execute_task`
- `duckdb_pending_execution_is_finished`
- `duckdb_pending_error`
- `duckdb_destroy_pending`
- `duckdb_execute_prepared_streaming`
- `duckdb_stream_fetch_chunk`

Batch B:
- `duckdb_appender_begin_row`
- `duckdb_appender_end_row`
- `duckdb_appender_flush`
- `duckdb_appender_close`
- `duckdb_appender_error`
