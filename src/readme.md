# Q2.jl

This package serves as an interface between Julia and [q/kdb+](https://code.kx.com/q/) (similar to [rkdb](https://github.com/KxSystems/rkdb)) so that commands and data can be sent to a remote kdb session and vice versa. The package serves as a replacement to the unmaintained [Q.jl](https://github.com/enlnt/Q.jl) with the main difference being fewer dependencies and a more minimal set of features (i.e. no Q/Julia prompt).

The package exports the types `KDBConnection` and `KDBHandle`, as well as the functions `open`, `close` and `execute`. Please see the function docstrings for more information.

## Type Conversions from KDB to Julia

The table below summarizes how types are converted from kdb to Julia

| **kdb/q**     	| **Julia from KDB**                        	| **Julia to KDB**                                              	|
|---------------	|-------------------------------------------	|---------------------------------------------------------------	|
| `boolean`     	| `Bool`                                    	| `Bool`                                                        	|
| `byte`        	| `UInt8`                                   	| `UInt8`                                                       	|
| `short`       	| `Int16`                                   	| `Int16`                                                       	|
| `int`         	| `Int32`                                   	| `Int32`                                                       	|
| `long`        	| `Int64`                                   	| `Int64`                                                       	|
| `real`        	| `Float32`                                 	| `Float32`                                                     	|
| `float`       	| `Float64`                                 	| `Float64`                                                     	|
| `char`        	| `Char`                                    	| `Char`                                                        	|
| `symbol`      	| `Symbol`                                  	| `Symbol`                                                      	|
| `timestamp`   	| `NanoDates.NanoDate`                      	| `TimesDates.TimeDate`, `<:Dates.AbstractDateTime`             	|
| `month`       	| `Date`                                    	| NA                                                            	|
| `date`        	| `Date`                                    	| `Dates.Date`                                                  	|
| `datetime`    	| `NanoDates.NanoDate`                      	| NA                                                            	|
| `timespan`    	| `Dates.Time`                              	| `Dates.Time`                                                  	|
| `minute`      	| `Minute`                                  	| NA                                                            	|
| `second`      	| `Second`                                  	| NA                                                            	|
| `time`        	| `Dates.Time`                              	| NA                                                            	|
| `table`       	| `NamedTuple`                              	| Any `Tables.jl` interface                                     	|
| `keyed table` 	| `NamedTuple`                              	| NA                                                            	|
| `dictionary`  	| `Dictionary{Symbol,Any}`                  	| `<:AbstractDictionary`                                        	|
| `atomic list` 	| `Vector{T}` or `Vector{Union{T,Missing}}` 	| Any iterator with `eltype` equal to `T` or `Union{T,Missing}` 	|
| `mixed list`  	| `Vector{Any}`                             	| Any iterator with `eltype = Any`                              	|

### Notes
 - Any null time or numeric value is converted to a `missing` when retrieved from KDB.
 - `NamedTuple` is intended to be the most basic type satisfying the `Tables.jl` `Tables.ColumnTable` interface. These can be wrapped as `DataFrames` via `DataFrame(named_tuple)`.
 - Unsupported kdb types: GUIDs, Functions

## Examples

```
using Q2
conn = KDBConnection(host="localhost", port=5555)

h = open(conn)
execute(h, "1 + til 10")
execute(h, "([]s:`a`b`c;a:11 22 33)")
execute(h, "10?(0nf,10?1f)")
close(h)

using DataFrames
tbl = DataFrame(x=randn(10),y=rand([:A,:B,:X],10))
open(conn) do h
    execute(h,"{.dat.mytbl:x}",tbl) # send table to kdb
    execute(h,".dat.mytbl") |> DataFrame # get the table back
end

```