# DuckDB.dyalog - DuckDB C-API wrapper for DyalogAPL
"DuckDB is an in-process SQL OLAP database management system" - [DuckDB](https://duckdb.org/)

## Installation of DuckDB 
Download latest libraries from [DuckDB Installation](https://duckdb.org/docs/installation/)

You should define the location of library in the [settings.json](./settings.json) file

```json
"duckdb":{
        "lib": "d:/duckdb/duckdb.dll"
```

## Use in Dyalog
```apl
]load DuckDB.dyalog
or
2 ⎕FIX 'file://DuckDB.dyalog' 
```

And then you are ready to go
```apl
  db←⎕NEW #.DB.DuckDB
  db.query 'SELECT 42 AS Number'
#.[DuckDB].[dbobject]
  (db.query'SELECT 42 AS Number').value
┌──────┐
│number│
├──────┤
│42    │
└──────┘  
  db.query 'CREATE VIEW airline AS SELECT * FROM parquet_scan(''airline.parquet'')' 
0
  a←db.query'SELECT * FROM airline LIMIT 5'
  a.value[;⍳5]
┌────┬───────┬─────┬──────────┬─────────┐
│Year│Quarter│Month│DayofMonth│DayOfWeek│
├────┼───────┼─────┼──────────┼─────────┤
│2019│3      │9    │2         │1        │
├────┼───────┼─────┼──────────┼─────────┤
│2019│3      │9    │3         │2        │
├────┼───────┼─────┼──────────┼─────────┤
│2019│3      │9    │4         │3        │
├────┼───────┼─────┼──────────┼─────────┤
│2019│3      │9    │5         │4        │
├────┼───────┼─────┼──────────┼─────────┤
│2019│3      │9    │6         │5        │
└────┴───────┴─────┴──────────┴─────────┘

```

At this point there are three functions:  `query` for the execution of query, `append` for appending data and `close` for closing the connection.
The main element in DuckDB wrapper is `dbobject`. The interface reads queries to a object and each object has `value`(default), `attributes` and `data` properties.   

```apl
  q←db.query 'CREATE TABLE test (id INT, name VARCHAR)'
  db.append 'test' '' ((1 2)('Matti' 'Pekka'))
  (db.query 'SELECT * FROM test').value
┌──┬─────┐
│id│name │
├──┼─────┤
│1 │Matti│
├──┼─────┤
│2 │Pekka│
└──┴─────┘ 
  (db.query 'SELECT * FROM test').data[]
┌───┬─────────────┐
│1 2│┌─────┬─────┐│
│   ││Matti│Pekka││
│   │└─────┴─────┘│
└───┴─────────────┘
  db.append'test' ''((db.query'SELECT * FROM test').data[])
  (db.query 'SELECT * FROM test').data[⊂'name']
┌─────────────────────────┐
│┌─────┬─────┬─────┬─────┐│
││Matti│Pekka│Matti│Pekka││
│└─────┴─────┴─────┴─────┘│
└─────────────────────────┘
  (db.query 'SELECT * FROM test').data['id' 'name']
┌───────┬─────────────────────────┐
│1 2 1 2│┌─────┬─────┬─────┬─────┐│
│       ││Matti│Pekka│Matti│Pekka││
│       │└─────┴─────┴─────┴─────┘│
└───────┴─────────────────────────┘
  (db.query'SELECT * FROM test').value[1 3 5;]
┌──┬─────┐
│id│name │
├──┼─────┤
│2 │Pekka│
├──┼─────┤
│2 │Pekka│
└──┴─────┘
  (db.query'SELECT * FROM test').attributes[]
┌────┬─────┐
│cols│types│
└────┴─────┘
  (db.query'SELECT * FROM test').attributes['cols' 'types']
┌─────────┬────┐
│┌──┬────┐│4 17│
││id│name││    │
│└──┴────┘│    │
└─────────┴────┘
  
```

I haven't implemented a possibility to create dbobjecct by yourself yet but It's coming.