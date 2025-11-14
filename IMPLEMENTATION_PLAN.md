# DuckDB C API Implementation Plan

## Current Status

**Implemented:** 48 functions (10.5% of total API)
**Total Available:** 458 functions in DuckDB C API
**Missing:** 410 functions (89.5%)

### Currently Implemented Functions

#### Database/Connection (4 functions)
- `duckdb_open`
- `duckdb_close`
- `duckdb_connect`
- `duckdb_disconnect`

#### Query Execution (2 functions)
- `duckdb_query`
- `duckdb_destroy_result`

#### Result Handling (8 functions)
- `duckdb_column_name`
- `duckdb_column_type`
- `duckdb_column_logical_type`
- `duckdb_column_count`
- `duckdb_row_count`
- `duckdb_rows_changed`
- `duckdb_result_error`
- `duckdb_result_get_chunk`
- `duckdb_result_chunk_count`

#### Prepared Statements (3 functions)
- `duckdb_prepare`
- `duckdb_destroy_prepare`
- `duckdb_execute_prepared`
- `duckdb_execute_prepared_arrow`

#### Logical Types (3 functions)
- `duckdb_create_logical_type`
- `duckdb_get_type_id`
- `duckdb_destroy_logical_type`

#### Data Chunks (6 functions)
- `duckdb_create_data_chunk`
- `duckdb_destroy_data_chunk`
- `duckdb_data_chunk_reset`
- `duckdb_data_chunk_get_column_count`
- `duckdb_data_chunk_get_vector`
- `duckdb_data_chunk_get_size`
- `duckdb_data_chunk_set_size`

#### Vectors (10 functions)
- `duckdb_vector_size`
- `duckdb_vector_get_column_type`
- `duckdb_vector_get_data`
- `duckdb_vector_get_validity`
- `duckdb_validity_row_is_valid`
- `duckdb_validity_set_row_validity`
- `duckdb_validity_set_row_invalid`
- `duckdb_validity_set_row_valid`
- `duckdb_vector_ensure_validity_writable`
- `duckdb_vector_assign_string_element`
- `duckdb_vector_assign_string_element_len`

#### Appender (3 functions)
- `duckdb_appender_create`
- `duckdb_append_data_chunk`
- `duckdb_appender_destroy`

#### Arrow Integration (8 functions)
- `duckdb_query_arrow`
- `duckdb_query_arrow_schema`
- `duckdb_arrow_column_count`
- `duckdb_arrow_row_count`
- `duckdb_arrow_rows_changed`
- `duckdb_query_arrow_error`
- `duckdb_destroy_arrow`

#### Utilities (2 functions)
- `duckdb_free`
- `duckdb_hugeint_to_double`

### Known Bug
**Line 98 in db/api.apln**: Function binding says `duckdb_query_arrow_schema` but should be `duckdb_query_arrow_array` based on the comment.

---

## Implementation Plan by Priority

### Priority 1: Core Functionality Enhancements (Essential for basic usage)

#### 1.1 Error Handling (4 functions) - **HIGH PRIORITY**
Essential for proper error reporting and debugging.

- `duckdb_create_error_data` - Create error objects
- `duckdb_destroy_error_data` - Clean up error objects
- `duckdb_error_data_error_type` - Get error type
- `duckdb_error_data_message` - Get error message
- `duckdb_error_data_has_error` - Check if error exists
- `duckdb_result_error_type` - Get result error type

#### 1.2 Configuration (5 functions) - **HIGH PRIORITY**
Allow users to configure database behavior.

- `duckdb_create_config` - Create configuration object
- `duckdb_config_count` - Get number of config options
- `duckdb_get_config_flag` - Get config flag info by index
- `duckdb_set_config` - Set configuration option
- `duckdb_destroy_config` - Destroy configuration
- `duckdb_open_ext` - Open database with config

#### 1.3 Connection Management (3 functions) - **HIGH PRIORITY**
Better control over connections.

- `duckdb_interrupt` - Interrupt running query
- `duckdb_query_progress` - Get query progress
- `duckdb_library_version` - Get DuckDB version

#### 1.4 Result Value Extraction (24 functions) - **HIGH PRIORITY**
Direct value access without data chunks (simpler API for small results).

- `duckdb_value_boolean`, `duckdb_value_int8`, `duckdb_value_int16`, `duckdb_value_int32`, `duckdb_value_int64`
- `duckdb_value_uint8`, `duckdb_value_uint16`, `duckdb_value_uint32`, `duckdb_value_uint64`
- `duckdb_value_hugeint`, `duckdb_value_uhugeint`, `duckdb_value_decimal`
- `duckdb_value_float`, `duckdb_value_double`
- `duckdb_value_date`, `duckdb_value_time`, `duckdb_value_timestamp`, `duckdb_value_interval`
- `duckdb_value_varchar`, `duckdb_value_string`, `duckdb_value_varchar_internal`, `duckdb_value_string_internal`
- `duckdb_value_blob`
- `duckdb_value_is_null`
- `duckdb_column_data` - Get raw column data pointer
- `duckdb_nullmask_data` - Get nullmask for column

#### 1.5 Prepared Statement Parameter Binding (25 functions) - **HIGH PRIORITY**
Critical for parameterized queries and SQL injection prevention.

- `duckdb_nparams` - Get parameter count
- `duckdb_parameter_name` - Get parameter name by index
- `duckdb_param_type` - Get parameter type
- `duckdb_param_logical_type` - Get parameter logical type
- `duckdb_clear_bindings` - Clear all bindings
- `duckdb_bind_boolean`, `duckdb_bind_int8`, `duckdb_bind_int16`, `duckdb_bind_int32`, `duckdb_bind_int64`
- `duckdb_bind_uint8`, `duckdb_bind_uint16`, `duckdb_bind_uint32`, `duckdb_bind_uint64`
- `duckdb_bind_hugeint`, `duckdb_bind_uhugeint`, `duckdb_bind_decimal`
- `duckdb_bind_float`, `duckdb_bind_double`
- `duckdb_bind_date`, `duckdb_bind_time`, `duckdb_bind_timestamp`, `duckdb_bind_timestamp_tz`, `duckdb_bind_interval`
- `duckdb_bind_varchar`, `duckdb_bind_varchar_length`, `duckdb_bind_blob`
- `duckdb_bind_null`
- `duckdb_bind_value` - Bind generic value object
- `duckdb_bind_parameter_index` - Get parameter index by name

#### 1.6 Prepared Statement Metadata (5 functions) - **HIGH PRIORITY**
Get information about prepared statements.

- `duckdb_prepare_error` - Get prepare error message
- `duckdb_prepared_statement_type` - Get statement type (SELECT, INSERT, etc.)
- `duckdb_prepared_statement_column_count` - Get result column count
- `duckdb_prepared_statement_column_name` - Get result column name
- `duckdb_prepared_statement_column_logical_type` - Get result column logical type
- `duckdb_prepared_statement_column_type` - Get result column type

### Priority 2: Extended Type System (Important for complex data)

#### 2.1 Extended Logical Types (35 functions) - **MEDIUM PRIORITY**
Support for complex types like lists, structs, maps, decimals.

**List Types:**
- `duckdb_create_list_type` - Create list type
- `duckdb_list_type_child_type` - Get list element type
- `duckdb_list_vector_get_size` - Get list vector size
- `duckdb_list_vector_set_size` - Set list vector size
- `duckdb_list_vector_get_child` - Get child vector of list

**Array Types:**
- `duckdb_create_array_type` - Create array type
- `duckdb_array_type_child_type` - Get array element type
- `duckdb_array_type_array_size` - Get fixed array size
- `duckdb_array_vector_get_child` - Get child vector

**Map Types:**
- `duckdb_create_map_type` - Create map type
- `duckdb_map_type_key_type` - Get map key type
- `duckdb_map_type_value_type` - Get map value type

**Struct Types:**
- `duckdb_create_struct_type` - Create struct type
- `duckdb_struct_type_child_count` - Get struct field count
- `duckdb_struct_type_child_name` - Get struct field name by index
- `duckdb_struct_type_child_type` - Get struct field type by index
- `duckdb_struct_vector_get_child` - Get child vector

**Union Types:**
- `duckdb_create_union_type` - Create union type
- `duckdb_union_type_member_count` - Get union member count
- `duckdb_union_type_member_name` - Get union member name
- `duckdb_union_type_member_type` - Get union member type

**Decimal Types:**
- `duckdb_create_decimal_type` - Create decimal type with width/scale
- `duckdb_decimal_width` - Get decimal width
- `duckdb_decimal_scale` - Get decimal scale
- `duckdb_decimal_internal_type` - Get underlying storage type

**Enum Types:**
- `duckdb_create_enum_type` - Create enum from strings
- `duckdb_enum_internal_type` - Get enum storage type
- `duckdb_enum_dictionary_size` - Get enum value count
- `duckdb_enum_dictionary_value` - Get enum value by index

**String/Varchar Types:**
- `duckdb_create_varchar_type` - Create varchar with collation

**Other:**
- `duckdb_logical_type_get_alias` - Get type alias
- `duckdb_logical_type_set_alias` - Set type alias

#### 2.2 Date/Time Conversions (12 functions) - **MEDIUM PRIORITY**
Convert between internal formats and human-readable structs.

- `duckdb_from_date` - Convert date to struct
- `duckdb_to_date` - Convert struct to date
- `duckdb_is_finite_date` - Check if date is finite
- `duckdb_from_time` - Convert time to struct
- `duckdb_to_time` - Convert struct to time
- `duckdb_create_time_tz` - Create time with timezone
- `duckdb_from_time_tz` - Convert time_tz to struct
- `duckdb_from_timestamp` - Convert timestamp to struct
- `duckdb_to_timestamp` - Convert struct to timestamp
- `duckdb_is_finite_timestamp` - Check if timestamp is finite
- `duckdb_is_finite_timestamp_s/ms/ns` - Check finite for different precisions

#### 2.3 Numeric Conversions (6 functions) - **MEDIUM PRIORITY**
Convert between numeric types.

- `duckdb_double_to_hugeint` - Convert double to hugeint
- `duckdb_uhugeint_to_double` - Convert uhugeint to double
- `duckdb_double_to_uhugeint` - Convert double to uhugeint
- `duckdb_double_to_decimal` - Convert double to decimal
- `duckdb_decimal_to_double` - Convert decimal to double (already implemented)

#### 2.4 Value API (77 functions) - **MEDIUM PRIORITY**
Create and manipulate value objects (alternative to prepared statement bindings).

**Value Creation (38 functions):**
- `duckdb_create_varchar`, `duckdb_create_varchar_length`
- `duckdb_create_bool`, `duckdb_create_int8/16/32/64`, `duckdb_create_uint8/16/32/64`
- `duckdb_create_hugeint`, `duckdb_create_uhugeint`, `duckdb_create_bignum`, `duckdb_create_decimal`
- `duckdb_create_float`, `duckdb_create_double`
- `duckdb_create_date`, `duckdb_create_time`, `duckdb_create_time_ns`, `duckdb_create_time_tz_value`
- `duckdb_create_timestamp`, `duckdb_create_timestamp_tz`, `duckdb_create_timestamp_s/ms/ns`
- `duckdb_create_interval`
- `duckdb_create_blob`, `duckdb_create_bit`, `duckdb_create_uuid`
- `duckdb_create_struct_value`, `duckdb_create_list_value`, `duckdb_create_array_value`, `duckdb_create_map_value`
- `duckdb_create_union_value`, `duckdb_create_enum_value`
- `duckdb_create_null_value`

**Value Extraction (37 functions):**
- `duckdb_get_bool`, `duckdb_get_int8/16/32/64`, `duckdb_get_uint8/16/32/64`
- `duckdb_get_hugeint`, `duckdb_get_uhugeint`, `duckdb_get_bignum`, `duckdb_get_decimal`
- `duckdb_get_float`, `duckdb_get_double`
- `duckdb_get_date`, `duckdb_get_time`, `duckdb_get_time_ns`, `duckdb_get_time_tz`
- `duckdb_get_timestamp`, `duckdb_get_timestamp_tz`, `duckdb_get_timestamp_s/ms/ns`
- `duckdb_get_interval`
- `duckdb_get_value_type`, `duckdb_get_blob`, `duckdb_get_bit`, `duckdb_get_uuid`, `duckdb_get_varchar`
- `duckdb_get_map_size`, `duckdb_get_map_key`, `duckdb_get_map_value`
- `duckdb_get_list_size`, `duckdb_get_list_child`
- `duckdb_get_enum_value`, `duckdb_get_struct_child`
- `duckdb_is_null_value`

**Value Utilities (2 functions):**
- `duckdb_destroy_value`
- `duckdb_value_to_string` - Convert value to string representation

### Priority 3: Advanced Query Features (Important for performance)

#### 3.1 Streaming Results (2 functions) - **MEDIUM PRIORITY**
Process large result sets incrementally.

- `duckdb_execute_prepared_streaming` - Execute with streaming results
- `duckdb_result_is_streaming` - Check if result is streaming
- `duckdb_result_return_type` - Get result return type (streaming vs materialized)

#### 3.2 Async/Pending Execution (11 functions) - **MEDIUM PRIORITY**
Non-blocking query execution.

- `duckdb_pending_prepared` - Create pending result from prepared statement
- `duckdb_pending_prepared_streaming` - Create pending streaming result
- `duckdb_destroy_pending` - Destroy pending result
- `duckdb_pending_error` - Get pending error message
- `duckdb_pending_execute_task` - Execute one task
- `duckdb_pending_execute_check_state` - Check state without execution
- `duckdb_execute_pending` - Get final result from pending
- `duckdb_pending_execution_is_finished` - Check if execution finished

#### 3.3 Statement Extraction (4 functions) - **MEDIUM PRIORITY**
Parse and prepare multiple statements from SQL string.

- `duckdb_extract_statements` - Extract statements from SQL
- `duckdb_prepare_extracted_statement` - Prepare specific extracted statement
- `duckdb_extract_statements_error` - Get extraction error
- `duckdb_destroy_extracted` - Destroy extracted statements

#### 3.4 Task/Threading API (8 functions) - **LOW PRIORITY**
Manual control over parallel execution.

- `duckdb_create_task_state` - Create task state
- `duckdb_execute_tasks` - Execute tasks
- `duckdb_execute_tasks_state` - Execute tasks with state
- `duckdb_execute_n_tasks_state` - Execute N tasks
- `duckdb_finish_execution` - Wait for completion
- `duckdb_task_state_is_finished` - Check if finished
- `duckdb_destroy_task_state` - Destroy task state
- `duckdb_execution_is_finished` - Check execution finished

### Priority 4: Extended Data Operations

#### 4.1 Enhanced Appender (34 functions) - **MEDIUM PRIORITY**
More appender operations for bulk insert optimization.

**Appender Metadata:**
- `duckdb_appender_column_count` - Get column count
- `duckdb_appender_column_type` - Get column type
- `duckdb_appender_error` - Get appender error

**Row-based Appending (alternative to data chunks):**
- `duckdb_appender_begin_row` - Start new row
- `duckdb_appender_end_row` - Finish current row
- `duckdb_append_bool`, `duckdb_append_int8/16/32/64`, `duckdb_append_uint8/16/32/64`
- `duckdb_append_hugeint`, `duckdb_append_uhugeint`
- `duckdb_append_float`, `duckdb_append_double`
- `duckdb_append_date`, `duckdb_append_time`, `duckdb_append_timestamp`, `duckdb_append_interval`
- `duckdb_append_varchar`, `duckdb_append_varchar_length`, `duckdb_append_blob`
- `duckdb_append_null`
- `duckdb_append_default` - Append column default value

**Flushing:**
- `duckdb_appender_flush` - Flush buffered rows
- `duckdb_appender_close` - Close appender

#### 4.2 String Utilities (3 functions) - **LOW PRIORITY**
String handling helpers.

- `duckdb_string_is_inlined` - Check if string is inline
- `duckdb_string_t_length` - Get string_t length
- `duckdb_string_t_data` - Get string_t data pointer

#### 4.3 Memory Management (1 function) - **LOW PRIORITY**
- `duckdb_malloc` - Allocate memory (duckdb_free already implemented)

### Priority 5: Advanced Features (Optional/Specialized)

#### 5.1 Table Description (5 functions) - **LOW PRIORITY**
Query schema information.

- `duckdb_get_table_names` - Get all table names with query
- (Other table description functions to be identified)

#### 5.2 Replacement Scan (3 functions) - **LOW PRIORITY**
Custom table resolution for virtual tables.

- `duckdb_add_replacement_scan` - Register replacement scan callback
- `duckdb_replacement_scan_set_function_name` - Set function name
- `duckdb_replacement_scan_add_parameter` - Add parameter

#### 5.3 Profiling (5 functions) - **LOW PRIORITY**
Query performance analysis.

- `duckdb_get_profiling_info` - Get profiling info
- `duckdb_profiling_info_get_value` - Get specific metric
- `duckdb_profiling_info_get_child_count` - Get child count
- `duckdb_profiling_info_get_child` - Get child info
- `duckdb_destroy_profiling_info` - Destroy profiling info

#### 5.4 Expression API (3 functions) - **LOW PRIORITY**
Build expressions programmatically.

- `duckdb_create_expression` - Create expression
- `duckdb_destroy_expression` - Destroy expression
- (Other expression functions)

#### 5.5 Instance Cache (2 functions) - **LOW PRIORITY**
Manage multiple database instances.

- `duckdb_create_instance_cache` - Create cache
- `duckdb_get_or_create_from_cache` - Get/create instance
- `duckdb_destroy_instance_cache` - Destroy cache

#### 5.6 Client Context (3 functions) - **LOW PRIORITY**
Access connection internals.

- `duckdb_connection_get_client_context` - Get client context
- `duckdb_client_context_get_connection_id` - Get connection ID
- `duckdb_destroy_client_context` - Destroy context

#### 5.7 Arrow Options (3 functions) - **LOW PRIORITY**
Configure Arrow integration.

- `duckdb_connection_get_arrow_options` - Get Arrow options
- `duckdb_result_get_arrow_options` - Get result Arrow options
- `duckdb_destroy_arrow_options` - Destroy Arrow options
- Additional Arrow functions:
  - `duckdb_create_arrow_stream` - Create Arrow stream
  - `duckdb_destroy_arrow_stream` - Destroy Arrow stream
  - `duckdb_destroy_arrow_converted_schema` - Destroy converted schema

### Priority 6: User-Defined Functions (Specialized/Advanced)

#### 6.1 Scalar Functions (24 functions) - **LOW PRIORITY**
Create custom scalar functions in APL.

- `duckdb_create_scalar_function` - Create scalar function
- `duckdb_destroy_scalar_function` - Destroy scalar function
- `duckdb_create_scalar_function_set` - Create function set
- `duckdb_destroy_scalar_function_set` - Destroy function set
- `duckdb_scalar_function_set_name` - Set function name
- `duckdb_scalar_function_add_parameter` - Add parameter
- `duckdb_scalar_function_set_return_type` - Set return type
- `duckdb_scalar_function_set_function` - Set implementation
- `duckdb_scalar_function_set_extra_info` - Set extra info
- Plus binding/execution helper functions

#### 6.2 Aggregate Functions (15 functions) - **LOW PRIORITY**
Create custom aggregate functions in APL.

- `duckdb_create_aggregate_function` - Create aggregate
- `duckdb_destroy_aggregate_function` - Destroy aggregate
- `duckdb_create_aggregate_function_set` - Create function set
- `duckdb_destroy_aggregate_function_set` - Destroy function set
- Plus configuration and execution functions

#### 6.3 Table Functions (12 functions) - **LOW PRIORITY**
Create virtual tables from APL data.

- `duckdb_create_table_function` - Create table function
- `duckdb_destroy_table_function` - Destroy table function
- Plus binding and data provision functions

#### 6.4 Cast Functions (10 functions) - **LOW PRIORITY**
Custom type casting.

- `duckdb_create_cast_function` - Create cast function
- `duckdb_destroy_cast_function` - Destroy cast function
- Plus configuration functions

#### 6.5 Function Registration (1 function) - **LOW PRIORITY**
- `duckdb_register_logical_type` - Register custom logical type

---

## Implementation Phases

### Phase 1: Essential Core (3-4 weeks)
Implement Priority 1 functions (62 functions):
- Error handling (6 functions)
- Configuration (6 functions)
- Connection management (3 functions)
- Result value extraction (24 functions)
- Prepared statement binding (25 functions)
- Prepared statement metadata (6 functions)
- Fix bug on line 98

**Deliverable:** Robust prepared statement support with proper error handling and configuration.

### Phase 2: Extended Types (2-3 weeks)
Implement Priority 2 functions (130 functions):
- Extended logical types (35 functions)
- Date/time conversions (12 functions)
- Numeric conversions (6 functions)
- Value API (77 functions)

**Deliverable:** Full support for complex types (lists, structs, maps, decimals).

### Phase 3: Performance Features (2 weeks)
Implement Priority 3 functions (19 functions):
- Streaming results (3 functions)
- Async/pending execution (11 functions)
- Statement extraction (4 functions)
- Task/threading (8 functions) - optional

**Deliverable:** Non-blocking queries and large result set handling.

### Phase 4: Data Operations (1-2 weeks)
Implement Priority 4 functions (38 functions):
- Enhanced appender (34 functions)
- String utilities (3 functions)
- Memory management (1 function)

**Deliverable:** Optimized bulk insert operations.

### Phase 5: Advanced Features (1-2 weeks)
Implement Priority 5 functions (24 functions):
- Table description (5 functions)
- Replacement scan (3 functions)
- Profiling (5 functions)
- Expression API (3 functions)
- Instance cache (3 functions)
- Client context (3 functions)
- Arrow options (6 functions)

**Deliverable:** Advanced database introspection and optimization tools.

### Phase 6: UDF Support (3-4 weeks - Optional)
Implement Priority 6 functions (61 functions):
- Scalar functions (24 functions)
- Aggregate functions (15 functions)
- Table functions (12 functions)
- Cast functions (10 functions)

**Deliverable:** Full user-defined function support (requires careful FFI callback design).

---

## Testing Strategy

For each phase:
1. Add comprehensive tests to `db/test.aplf`
2. Test with real-world use cases
3. Verify memory management (no leaks)
4. Test error handling paths
5. Document new functions in CLAUDE.md

## Documentation Updates

After each phase:
1. Update CLAUDE.md with new function descriptions
2. Add usage examples to Jupyter notebook
3. Document type mappings between DuckDB and APL
4. Create migration guide for users of older versions

## Backward Compatibility

All new functions should be additive - existing code should continue to work without modification.

---

## Notes

- **Total Implementation Effort:** Estimated 14-19 weeks for full coverage (excluding UDF support)
- **Minimum Viable Extension:** Phase 1 alone adds the most critical missing functionality
- **Quick Wins:** Phases 1-3 (9-10 weeks) cover 90% of typical use cases
- **FFI Challenges:** UDF support (Phase 6) requires callback functions from C to APL, which may have technical limitations in Dyalog's ⎕NA
