using Q2
using Dates, TimesDates
using DataFrames

conn = KDBConnection(host="localhost", port=5555)
x = execute(conn,".z.P")




x = execute(conn,"{.dat.a:x}", NanoDate(now()))
x = execute(conn,"{.dat.b:x+y;}",1,2)
x = execute(conn,"{.dat.c:x}",Dict(:a => Float64(π), :b => π-3); async=true)

using DataFrames
tbl0 = DataFrame(x=randn(10), y=rand([:A, :B, :X, missing], 10))
tbl1 = open(conn) do h
    execute(h, "{.dat.mytbl:x}", tbl0) # send table to kdb
    execute(h, ".dat.mytbl") |> DataFrame # get the table back
end


using Q2
using Q2.K_lib
import Q2.K_lib


h = Q2.hopen("localhost",5555)



