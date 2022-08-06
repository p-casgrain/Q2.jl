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





using Pkg.Artifacts
artifact_toml = joinpath(@__DIR__, "Artifacts.toml")
iris_hash = artifact_hash("kdb-c-lib", artifact_toml)

using ArtifactUtils

julia > add_artifact!(
    "Artifacts.toml",
    "kdb-c-lib",
    "https://github.com/KxSystems/kdb/blob/master/m64/c.o",
    force=true,
    platform="m64"
)


# xx = K_Object(K_lib.ks("abcd"))
# access_value(xx)

# close!(conn)


# [:a, :b, :c] |> convert_jl_to_k |> access_value
# ["abcd", "efg"] |> convert_jl_to_k |> access_value

# x0 = convert_jl_to_k([1, 2, 3])
# x1 = convert_jl_to_k([1, 2, 3])

# z0 = K_Object(K_lib.ktn(0, 0))
# K_lib.jk(Ref(z0.k), K_lib.r1(x1.k))

# Date(2000):Day(1):Date(2000, 03)

k0 = convert_jl_to_k(1)
k1 = convert_jl_to_k(:a)

l0 = ccall((:knk, K_lib.C_LIBQ), K_lib.K, (K_lib.I, K_lib.K...), 2, k0.k, k1.k) |> K_Object |> access_value

K_lib.knk(k0.k, k1.k) |> access_value








# kobj.k.n |> unsafe_load
# kobj

# k2 = (kobj.k + 16) |> K_Object |> upref!
# k2.k.n |> unsafe_load



# xx = [[1, 2, 3] [1, 2, 3]]
# size(1:10)

# CartesianIndices(xx)
# eachslice(xx, dims=1)


# xx = K_Object(K_lib.kp("abcd"))
# xx |> access_value

# xx = UInt8(32)
# jl_to_katom_type(xx)
# kt = jl_to_katom_cval(xx)

# K_lib.kg(UInt8(32)) |> K_Object

# xx = randn(3, 3)
# yy = eachslice(xx, dims=1)
# eltype(yy |> first)

# Base.IteratorSize(xx)

# size((x^2 for x in 1:10))
# length((x^2 for x in 1:10))

# Base.IteratorEltype(xx)




