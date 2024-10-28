# KdbConnect.jl

This package serves as an interface between Julia and [q/kdb](https://code.kx.com/q/) (similar to [rkdb](https://github.com/KxSystems/rkdb)) so that data can be sent to and received from a kdb session. It includes two parts. First is the Julia interface, which lets a Julia process connect to a q/kdb server and exchange data. The second is a kdb interface  `J.q` (like [embedPy](https://github.com/KxSystems/embedPy)) which allows julia to be run from within a kdb/q process.

**Note:** Currently only Mac and Linux have been tested and are known to be supported.

## Julia Interface

The package exports the types `KdbConnectionInfo` and `KdbHandle`, as well as the functions `open`, `close!` and `execute`. Please see the function docstrings and examples below for more information.

### Installation
Just run `using Pkg; Pkg.add(KdbConnect)` as you would normally.

### Examples

```julia
using KdbConnect
conn = KdbConnectionInfo(host="localhost", port=1234) # alo supports password, etc.

# one method of opening connections
h = open(conn)
mytable = execute(h,"n:`int\$1e3;([]a:n?100;b:n?1000f;c:n?`4)")
mylist1 = execute(h, "1+til 10")
mylist2 = execute(h, "25?(0nf,10?1f)")
myatom1 = execute(h, ".z.P")
close!(h)

# another method of opening connections (opens and closes automatically)
tbl = DataFrame(x=randn(500),y=rand([:A,:B,:X],500))
open(conn) do h
    execute(h,"show",tbl) # send table to kdb + display it
    execute(h,"{til[10],x}",[1,2,3,:abcd,missing,nothing,[:paul,:john,:george,:ringo]])
end
```

## kdb/q interface

Once installed (see below), run `\l J.q` to load the package. Julia session is started on package load.
This package contains the following functions:
 - `.J.e[x]` - executes a string `x` and shows result (never returns). 
 - `.J.er[x]` - executes a string `x` and return result as native `q` object (if possible. See table on conversions).
 - `.J.wrapfn[x]` - wraps a Julia function with name contained in string `x` as kdb function.
 - `.J.set[nm;x]` - takes a kdb object `x` and assigns it to variable named `nm` (string/sym) in the Julia global namespace.
 - `.J.repl[]` - launches the Julia REPL for current session. `ctrl+D` to close the REPL and go back to `q)`. Useful for debugging.

### Notes
The first available julia binary available in the `PATH` will be used. Requires `KdbConnect.jl` to be available for full functionality, warning will be given if not available. The conversion of objects between q and julia are done using `KdbConnect.jl`, so the same conversion rules apply (see type conversions section).
The following optional environment variables are read when loading the package
 - `EMBEDJL_CMD_ARGS` - string containing additional command arguments (example: `--threads auto --home=... -O 3`)
 - `EMBEDJL_RUN_CMD` - string containing commands to be run in julia directly after launch

### Installation

Run `git clone https://github.com/p-casgrain/KdbConnect.jl` somewhere, `cd` into the `embed/` folder and run `make all && make install` to install the package. This will install the package into your `$QHOME`.

### Examples

```
\l J.q

.J.e "v=[1,2,3,4,5]; @show v";                  / run but don't return
J)prod(tanh.(1:100))                            / does the same but without quotes or escapes
x:.J.er "5.*v";                                 / eval and return, save result to variable x
fn:.J.wrapfn["sum"];                            / wrap a function (must be available in global Julia namespace)
fn[1;2;3;4]; fn[100?1f];                        / eval wrapped function with any number of arguments
.J.set["myqlist";20?`4]; .J.e "@show myqlist";  / assign variable in julia 
```



# Type Conversions

## kdb/q $\rightarrow$ Julia
 
| **kdb/q type** | **Received by Julia**                     |
| :------------- | :---------------------------------------- |
| `bool`         | `Bool`                                    |
| `byte`         | `UInt8`                                   |
| `short`        | `Int16`                                   |
| `int`          | `Int32`                                   |
| `long`         | `Int64`                                   |
| `real`         | `Float32`                                 |
| `float`        | `Float64`                                 |
| `char`         | `Char`                                    |
| `symbol`       | `Symbol`                                  |
| `timestamp`    | `TimesDates.TimeDate`                     |
| `month`        | `Date`                                    |
| `date`         | `Date`                                    |
| `datetime`     | `TimesDates.TimeDate`                     |
| `timespan`     | `Dates.Time`                              |
| `minute`       | `Minute`                                  |
| `second`       | `Second`                                  |
| `time`         | `Dates.Time`                              |
| `table`        | `DataFrame`                               |
| `keyed table`  | `DataFrame`                               |
| `dictionary`   | `Dictionary{Symbol,T}`                    |
| `atomic list`  | `Vector{T}` or `Vector{Union{T,Missing}}` |
| `mixed list`   | `Vector{Any}`                             |
| `functions`    | Unsupported                               |


## Julia $\rightarrow$ kdb/q

| **Julia Type**                                                                                   | **Received by kdb/q** |
| :----------------------------------------------------------------------------------------------- | :-------------------- |
| `Bool`                                                                                           | `bool`                |
| `UInt8`                                                                                          | `byte`                |
| `Int16`                                                                                          | `short`               |
| `Int32`                                                                                          | `int`                 |
| `Int64`                                                                                          | `long`                |
| `Float32`                                                                                        | `real`                |
| `Float64`                                                                                        | `float`               |
| `Char`                                                                                           | `char`                |
| `String`                                                                                         | `string`              |
| `Symbol`                                                                                         | `symbol`              |
| `TimesDates.TimeDate`, `<:Dates.AbstractDateTime`                                                | `timestamp`           |
| `Dates.Date`                                                                                     | `date`                |
| `Dates.Time`                                                                                     | `timespan`            |
| `<:AbstractDictionary`                                                                           | `dictionary`          |
| Any table supporting `Tables.jl` interface <br> (e.g. `DataFrame`)                               | `table`               |
| Any iterator with `eltype` equal to `T` or `Union{T,Missing}` <br> (e.g. `Array`,`Vector`, etc.) | `atomic list`         |
| Any other iterator with `eltype <: Any`                                                          | `mixed list`          |

## Notes
 - Additional types not explicitly listed above are also supported, as long as they can be implicitly converted into one of the above (i.e. `<:Real`,`<:Integer`, etc.)
 - Any null time or numeric value is converted to a `missing` when it is in an Atomic list. For example the list `0 2 3 0Nj` in q will converted to a `Union{Float64,Missing}[0,2,3,missing]`, however this conversion will not occur if this is a mixed list or an atom, since it is impossible to know the type of the `missing` value in these cases.
 - Unsupported kdb types for conversions: GUIDs, Functions. These may be converted to `nothing` when sent to Julia


# Acknowledgements

The package design and many other aspects were based on the defunct [Q.jl](https://github.com/enlnt/Q.jl). This package aims to be a replacement, with the main difference being fewer dependencies and a more minimal set of features. 