using Q2
using Q2: K_lib, K_Object, ATOM_TYPES, access_value
using Q2: convert_jl_to_k, jl_to_katom_type, jl_to_katom_cval, new_katom, convert_jl_to_k
using Dates
import NanoDates: NanoDate
using InteractiveUtils
using DataFrames
using Tables
using BenchmarkTools


using Q2
conn = KDBConnection(host="localhost", port=5555)

execute(conn, "{.data.b:x}", rand(Float32, 10, 10))
execute(conn, ".data.b")



res = execute(conn, "([] x:til 10; y:10?1f; z:.z.t+`minute\$10?100i)") |> DataFrame


execute(conn, "([] w:10?(0nj,til 3) ;x:10?1f ; y:10?(12;1b;`foo;\"bar\") ; z:10?`3)") |> DataFrame

execute(conn, "{b:x}", 3.14159)


typemin(Date)
typemax(TimeDate)

using DataFrames
tbl0 = DataFrame(x=randn(10), y=rand([:A, :B, :X, missing], 10))
tbl1 = open(conn) do h
    execute(h, "{.dat.mytbl:x}", tbl0) # send table to kdb
    execute(h, ".dat.mytbl") |> DataFrame # get the table back
end






