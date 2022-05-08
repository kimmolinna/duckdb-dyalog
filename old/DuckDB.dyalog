:Namespace DB    
    ∇ r←init;lib;wf;o
      ⎕FR←1287
      'set'⎕NA'U Kernel32|SetCurrentDirectory* <0T'
      wf←⊃⎕NPARTS #.DB{⍺{0=≢⍵:⍺.SALT_Data.SourceFile ⋄ ⍵}' '~⍨⊃⍵{⍵[⍸(⊂⍺){∨/⍺⍷⍵}¨⍵]}⊃¨5176⌶⍬}'DuckDB.dyalog'
      o←set ⊂wf
      #.settings←⎕JSON⊃⎕NGET wf,'settings.json'
      lib←#.settings.duckdb.lib
      'get_pointers'⎕NA'dyalog64|MEMCPY >P[] P P'
      'char'⎕NA'dyalog64|MEMCPY >0C[] P P'
      'int8'⎕NA'dyalog64|MEMCPY >I1[] P P'
      'int16'⎕NA'dyalog64|MEMCPY >I2[] P P'
      'int32'⎕NA'dyalog64|MEMCPY >I4[] P P'
      'int64'⎕NA'dyalog64|MEMCPY >I8[] P P'
      'uint8'⎕NA'dyalog64|MEMCPY >U1[] P P'
      'uint16'⎕NA'dyalog64|MEMCPY >U2[] P P'
      'uint32'⎕NA'dyalog64|MEMCPY >U4[] P P'
      'uint64'⎕NA'dyalog64|MEMCPY >U8[] P P'
      'float'⎕NA'dyalog64|MEMCPY >F4[] P P'
      'double'⎕NA'dyalog64|MEMCPY >F8[] P P'
      'utf8'⎕NA'dyalog64|MEMCPY >0UTF8[] P P'
      'utf'⎕NA'dyalog64|STRNCPY >0UTF8[] P P'
      'interval'⎕NA'dyalog64|MEMCPY >{I4 I4 I8}[] P P'
      ⎕NA'I4 ',lib,'|duckdb_open <0UTF8[] >P'
      ⎕NA'I4 ',lib,'|duckdb_connect P >P'
      ⎕NA'I4 ',lib,'|duckdb_query P <0UTF8[] >P[]'
      ⎕NA lib,'|duckdb_destroy_result <P[]'
      ⎕NA lib,'|duckdb_free P'      
      ⎕NA lib,'|duckdb_disconnect <P'  
      ⎕NA lib,'|duckdb_close <P'  
      ⎕NA'I4 ',lib,'|duckdb_appender_create P <0UTF8[] <0UTF8[] >P'  
      'BOOLEAN' ⎕NA'I4 ',lib,'|duckdb_append_bool P I1'
      'TINYINT' ⎕NA'I4 ',lib,'|duckdb_append_int8 P I1'
      'SMALLINT' ⎕NA'I4 ',lib,'|duckdb_append_int16 P I2'
      'INTEGER' ⎕NA'I4 ',lib,'|duckdb_append_int32 P I4'
      'BIGINT' ⎕NA'I4 ',lib,'|duckdb_append_int64 P I8'
      'UTINYINT' ⎕NA'I4 ',lib,'|duckdb_append_uint8 P U1'
      'USMALLINT' ⎕NA'I4 ',lib,'|duckdb_append_uint16 P U2'
      'UINTEGER' ⎕NA'I4 ',lib,'|duckdb_append_uint32 P U4'
      'UBIGINT' ⎕NA'I4 ',lib,'|duckdb_append_uint64 P U8'
      'REAL' ⎕NA'I4 ',lib,'|duckdb_append_float P F4'
      'DOUBLE' ⎕NA'I4 ',lib,'|duckdb_append_double P F8'
      'VARCHAR' ⎕NA'I4 ',lib,'|duckdb_append_varchar P <0UTF8[]'
      'TIMESTAMP' ⎕NA'I4 ',lib,'|duckdb_append_int64 P I8'      
      'NULL' ⎕NA'I4 ',lib,'|duckdb_append_null P'
      ⎕NA'I4 ',lib,'|duckdb_appender_end_row P'
      ⎕NA'I4 ',lib,'|duckdb_appender_destroy <P'        
    ∇

    :class dbobject
        ⎕ML←1 ⋄ ⎕IO←1 ⋄ ⎕PP←34
        :Field private _data←⍬
        :field private _a←⊂''
        :field private ga←⍬

        :property keyed attributes
        :access public

            ∇ r←Get args
              :If args.IndexersSpecified
                  r←{0=≢⍵:⊂'' ⋄ ⍵[ga⍳⊃args.Indexers]}_a
              :Else
                  r←(~_a∊⊂'')/ga
              :EndIf
            ∇

            ∇ Set args
              :If (⊂'')≡_a ⋄ _a←(⊂'')⍴⍨≢ga ⋄ :EndIf
              _a[ga⍳⊃args.Indexers]←args.NewValue
            ∇
        :endproperty

        :property default value
        :Access Public

            ∇ r←Get args
              r←(⊃attributes[⊂'cols']){1=≢⍺:⍺{1=≢⍵:⍺⍪[0.5]⍵⋄⍺⍪⍪⍵}⍵⋄⍺{1=≢⊃⍵:⍺⍪[0.5]⍵⋄⍺⍪⍉↑⍵}⍵}_data
            ∇
        :endproperty

        :property keyed data
        :Access Public

            ∇ r←Get args;i
             :If args.IndexersSpecified
                  :if ∧/83=⎕dr¨⊃args.Indexers
                    :if 1<⍴,⊃args.Indexers 
                      r←{0=≢⍵:⊂'' ⋄ ⍵[⊃,args.Indexers]}_data
                    :else
                      r←{0=≢⍵:⊂'' ⋄ ⍵[⊂,args.Indexers]}_data
                    :endif
                  :else
                    i←(⊃attributes[⊂'cols'])⍳⊃args.Indexers
                    r←{0=≢⍵:⊂'' ⋄ ⍵[i]}_data
                  :endif  
              :Else
                  r←_data
              :EndIf
            ∇  

            ∇ Set args
              :If (⊂'')≡_a ⋄ _a←(⊂'')⍴⍨≢ga ⋄ :EndIf
              _a[ga⍳⊃args.Indexers]←args.NewValue
            ∇

        :endproperty


        ∇ Make2 arg
          :Access Public
          :Implements Constructor
          ga←#.settings.duckdb.attributes
          attributes[⊃⊃arg]←2⊃⊃arg
          _data←{1=≢⍵:,↑⍵ ⋄ ⍵}2⊃arg
        ∇

        ∇ Make0
          :Access Public
          :Implements Constructor
          ga←#.settings.duckdb.attributes
        ∇

    :endclass

    :Class DuckDB
    ⍝ Interface from Dyalog APL to DuckDB

        ⎕ML←1 ⋄ ⎕IO←0 ⋄ ⎕PP←34
        :field private type←⍬
        :field private ga←⍬
        :field private db_ptr
        :field private con_ptr
        :field private ts_corr←-10 ⎕DT ⊂2029 12 31 0 0 0 0

        prop←{83=⎕dr ⍵:⊂(⍺.name,⊂⍬)[⍺.code⍳⍵] ⋄ (⍺.code,0)[⍺.name⍳⊃⍵]}

        :property keyed DT
        :access public
            ∇ r←get args
              r←type prop args.Indexers
            ∇
        :endproperty

        ∇ out←append (table schema data);appender_ptr;st;r;types;t;i
            :Access public
            r←query'DESCRIBE ',table
            :if 9=⎕nc 'r'
                types←{↑⍵.data[][(↑⍵.attributes[⊂'cols'])⍳⊂'Type']}r
                :if (⍴types)=⍴data
                    (st appender_ptr)←#.DB.duckdb_appender_create con_ptr schema table 0   
                    :if st
                       out←'Unable to create an appender!'
                    :else
                       :if ∨/i←types∊⊂'TIMESTAMP'
                           data[⍸i]←1000÷⍨(-ts_corr)+10 ⎕dt data[⍸i] 
                       :endif

                       :for i :in ⍳⍴data
                            :for t :in ⍳⍴types
                                ⍎'st←#.DB.',(t⊃types),' appender_ptr (t i⊃data)'
                                :if st
                                  ∘
                                :endif
                            :endfor
                            
                            st←#.DB.duckdb_appender_end_row appender_ptr
                            :if st
                                ∘
                            :endif
                       :endfor 
                       st←#.DB.duckdb_appender_destroy appender_ptr
                    :endif
                :else
                    out←'Check the number of columns!'
                :endif
            :else
               out←r
            :endif
        ∇

        ∇ close;st
          :Access public
          st←#.DB.duckdb_disconnect con_ptr
          con_ptr←0
          st←#.DB.duckdb_close db_ptr
          db_ptr←0
        ∇
        
        ∇ open db_str;st;con
            ⍝ db_str: database name (with path) or :memory:
            ⍝ db_ptr: pointer to database
            ⍝ con_ptr: pointer to connection

            (st db_ptr)←#.DB.duckdb_open db_str 0
            :if st 
                db_ptr←0
            :else
                (st con_ptr)←#.DB.duckdb_connect db_ptr 0

                :if st ⋄ con_ptr←0 ⋄:endif
            :endif

        ∇               
        
        ∇ out←query str;st;column_count;row_count;row_changed;columns;error_message;internal_data;result;data;nullmask;type;cols;ind;i;rows;col;col_names;types;data_cols;f
            :Access public
            :if con_ptr=0
              out←'Connection is closed!' ⋄ →0
            :endif
            ⎕FR←1287
            :trap 0
                (st result)←#.DB.duckdb_query con_ptr str 6  
            :endtrap
            
            (column_count row_count row_changed columns error_message internal_data)←↑result

            :if 0≠error_message
                out←#.DB.utf8 1024 error_message 1024 ⋄ →0
            :endif 
            
            col_names←types←data_cols←⍬
            cols←#.DB.get_pointers (column_count×5) columns (column_count×5×8)     

            :for i :in ⍳column_count
              (data nullmask type name internal_data)←cols[(5×i)+⍳5] 
              nullmask←#.DB.int8 row_count nullmask row_count
            
              :if row_count=0 
                out←st 
                f←#.DB.duckdb_free data
                f←#.DB.duckdb_free columns
                 →0 
              :endif
            
              col_names,←⊂#.DB.utf8 1024 name 1024      
              
              :select type   
              :caselist 1 2   ⍝ boolean and tinyint
                col←#.DB.int8 row_count data row_count
              :case 3   ⍝ smallint
                col←#.DB.int16 row_count data (row_count×2)
              :case 4   ⍝ integer
                col←#.DB.int32 row_count data (row_count×4)
              :case 5   ⍝ bigint
                col←#.DB.int64 row_count data (row_count×8)
              :case 6   ⍝ utinyint
                col←#.DB.uint8 row_count data row_count
              :case 7   ⍝ usmallint
                col←#.DB.uint16 row_count data (row_count×2)
              :case 8   ⍝ uinteger
                col←#.DB.uint32 row_count data (row_count×4)
              :case 9   ⍝ ubigint
                col←#.DB.uint64 row_count data (row_count×8)
              :case 10  ⍝ float
                col←#.DB.float row_count data (row_count×4)
              :case 11  ⍝ double
                col←#.DB.double row_count data (row_count×8)
              :case 12  ⍝ timestamp
                col←10 ¯2⎕dt ts_corr+1000×#.DB.int64 row_count data (row_count×8)
              :case 13  ⍝ date
                col←3↑¨13 ¯1 ⎕DT #.DB.int32 row_count data (row_count×4)
              :case 14  ⍝ time
                col←3↓¨10 ¯2 ⎕DT 1000×#.DB.int64 row_count data(row_count×8)
              :case 15  ⍝ interval
                col←#.DB.interval row_count data(row_count×(4+4+8))
                col←{b←⍵≠0 ⋄ 2=⍸b:0 0,0 60 60 1000000⊤2⊃⍵⋄⍵ }¨col
              :case 16  ⍝ hugeint
                ∘
              :case 17  ⍝ varchar
                rows←#.DB.get_pointers row_count data (row_count×8)
                col←{∨/⍵:⍵\{o←#.DB.utf 256 ⍵ 256 ⋄ f←#.DB.duckdb_free ⍵ ⋄ o}¨⍵/rows ⋄ ⍵}~nullmask
              :case 18  ⍝ blob
                ∘    
              :endselect
              
              (nullmask/col)←⎕NULL       
              data_cols,←⊂col ⋄ types,←type
              f←#.DB.duckdb_free data
            :end
            
            f←#.DB.duckdb_free columns
⍝            f←#.DB.duckdb_destroy_result ,⊂result
            out←⎕NEW dbobject((ga (col_names types))data_cols)    
        ∇
        
        ∇ Make1 db_str 
          :Access public
          :Implements constructor
          :If 0=⎕NC'#.settings'
              DB.init                                                                                                                                        
          :EndIf
          type←#.settings.duckdb.type
          ga←#.settings.duckdb.attributes
          open db_str  
        ∇

        ∇ Make
          :Access public
          :Implements constructor
          Make1 ':memory:'  
        ∇

        ∇ UnMake;a;st
          :Implements destructor
          :Trap 0 ⍝ Ignore errors in teardown
                ∘
          :EndTrap
        ∇
    :endclass    
:EndNamespace