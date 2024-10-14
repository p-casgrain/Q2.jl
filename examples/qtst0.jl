import Pkg
Pkg.activate(".")

Pkg.add("TruncatedStacktraces")
using TruncatedStacktraces

using Q2


using Q2
using Dates, TimesDates
using DataFrames

conn = KDBConnection(host="localhost", port=5555)

x = execute(conn,"1.0")


x = execute(conn,"{.dat.a:x}", NanoDate(now()))
x = execute(conn,"{.dat.b:x+y;}",1,2)
x = execute(conn,"{.dat.c:x}",Dict(:a => Float64(π), :b => π-3); async=true)

using DataFrames
tbl0 = DataFrame(x=randn(10), y=rand([:A, :B, :X, missing], 10))
tbl1 = open(conn) do h
    execute(h, "{.dat.mytbl:x}", tbl0) # send table to kdb
    execute(h, ".dat.mytbl") |> DataFrame # get the table back
end


import Q2
using Q2.K_lib

h = Q2.hopen("localhost",5001)
# convert_jl_to_k(1)
res_kobj = Q2.K_Object(K_lib.k(h,"([]a:1 2 3;b:3?1f)",K_lib.K_NULL))
Q2.hclose(h)
Q2.access_value(res_kobj)

Q2.access_value(Q2.K_Object(K_lib.k(0,"1+1",K_lib.K_NULL)) )


using Revise, Pkg, DataFrames
using Q2
# Pkg.activate(".")

using BenchmarkTools, Profile

conn = KDBConnection(host="localhost", port=5001)
h = open(conn)
@show DataFrame(execute(h,"n:`int\$1e3;([]a:n?100;b:n?1000f)"))
execute(h,"show",5+1:10)
execute(h,"show",[1.0,2,3,:a])
close!(h)




# TESTING ZONE
res_kobj = Q2.K_Object(K_lib.k(h,"`float\$til[5]",K_lib.K_NULL))

using Q2.K_lib
h = Q2.hopen("localhost",5001)
res_kobj = Q2.K_Object(K_lib.k(h,"( (1 2 3); `a`c)",K_lib.K_NULL))
length(res_kobj.k)
K_lib.m9()

Q2.hclose(h)
Q2.access_value(res_kobj)


K_lib.xn(res_kobj.k)
K_lib.xr(res_kobj.k)
K_lib.kK(res_kobj.k)[1]





