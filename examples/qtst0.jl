# import Pkg
# Pkg.activate(".")

# Pkg.add("TruncatedStacktraces")
# using TruncatedStacktraces

# using Q2


# using Q2
# using Dates, TimesDates
# using DataFrames

# conn = KDBConnection(host="localhost", port=5555)

# x = execute(conn,"1.0")


# x = execute(conn,"{.dat.a:x}", NanoDate(now()))
# x = execute(conn,"{.dat.b:x+y;}",1,2)
# x = execute(conn,"{.dat.c:x}",Dict(:a => Float64(π), :b => π-3); async=true)

# using DataFrames
# tbl0 = DataFrame(x=randn(10), y=rand([:A, :B, :X, missing], 10))
# tbl1 = open(conn) do h
#     execute(h, "{.dat.mytbl:x}", tbl0) # send table to kdb
#     execute(h, ".dat.mytbl") |> DataFrame # get the table back
# end


# import Q2
# using Q2.K_lib

# h = Q2.hopen("localhost",5001)
# # convert_jl_to_k(1)
# res_kobj = Q2.K_Object(K_lib.k(h,"([]a:1 2 3;b:3?1f)",K_lib.K_NULL))
# Q2.hclose(h)
# Q2.access_value(res_kobj)

# Q2.access_value(Q2.K_Object(K_lib.k(0,"1+1",K_lib.K_NULL)) )


# ENV["IS_EMBEDDED_Q"] = "true"
using Revise, Pkg, DataFrames, PrecompileTools
Pkg.activate(".")
PrecompileTools.verbose[] = true



# using BenchmarkTools, Profile
@compile_workload begin
    using Q2
    using Q2.K_lib
    conn = KDBConnection(host="localhost", port=5001)
    h = open(conn)
    bigtbl = execute(h,"n:`int\$1e1;update d:string[c], e:count[i]#enlist[enlist (::)], f:.z.P, g:.z.D, h:`minute\$.z.P, j:\"e\"\$a from ([]a:n?100;b:n?1000f;c:n?`4)")
    execute(h,"{x}",5+1:10)
    execute(h,"{show x}",[1.0,2,3,:a,missing])
    execute(h,"{show x}",bigtbl)
    execute(h,"0Np,0Nj,0nf")
    close!(h)
end


@time execute(h,"n:`int\$1e6;([]a:n?100;b:n?1000f;c:n?`4)")


# x = Q2.K_Object(K_lib.K_NULL,own=false)


# # TESTING ZONE
# res_kobj = Q2.K_Object(K_lib.k(h,"`float\$til[5]",K_lib.K_NULL))

# using Q2.K_lib
# h = Q2.hopen("localhost",5001)
# res_kobj = Q2.K_Object(K_lib.k(h,"( (1 2 3); `a`c)",K_lib.K_NULL))
# length(res_kobj.k)
# K_lib.m9()

# Q2.hclose(h)
# Q2.access_value(res_kobj)


# K_lib.xn(res_kobj.k)
# K_lib.xr(res_kobj.k)
# K_lib.kK(res_kobj.k)[1]





