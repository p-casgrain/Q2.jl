
# open a kdb handle
hopen(host::String, port::Integer) = K_lib.khp(host, port)
hopen(host::String, port::Integer, user::String) = K_lib.khpu(host, port, user)
hopen(host::String, port::Integer, user::String, timeout::Integer) =
    K_lib.khpun(host, port, user, timeout)

# close a kdb handle
hclose(handle::Integer) = K_lib.kclose(handle)

function checkhandleok(x::Integer)
    x > 0 && return true
    x == 0 && return error("KDB Handle Authentication Error")
    x == -1 && error("KDB Connection Error")
    x == -2 && error("KDB Handle Timeout Error")
    return false
end

"""
    KDBConnection(host::String, port::Integer[, user::String, timeout::Integer])  

Information for a KDB connection. Requires `host` and `port`. `user and `timeout`are optional.`timeout` is an integer representing milliseconds until query timeout.

Open a connection with `open(conn::KDBConnection)`
"""
Base.@kwdef struct KDBConnection
    host::String
    port::Integer
    user::Union{String,Nothing} = nothing
    timeout::Union{Integer,Nothing} = nothing
end

"""
    KDBHandle(handle_int::Integer)

Handle for an open connection to a KDB instance.
Close handle with `close(h::KDBHandle)`.
Handle will automatically close when garbage collected.
"""
mutable struct KDBHandle
    handle::Int16
    isopen::Bool
    function KDBHandle(x::Integer)
        obj = new(x,true)
        finalizer(obj) do o
            hclose(o.handle)
        end
    end
end

Base.show(io::IO,h::KDBHandle) = print(io,"KDBHandle(h=$(h.handle),open=$(h.isopen))")

"""
    open(conn::KDBConnection)::KDBHandle

Open a connection to a KDB instance. Returns a `KDBHandle` to the open connection.
Also supports `do` syntax:

```
open(conn::KDBConnection) do h
    execute(h,...)
end
```
"""
function Base.open(conn::KDBConnection)
    if isnothing(conn.user) && isnothing(conn.timeout)
        h = hopen(conn.host, conn.port)
    elseif (!isnothing(conn.user)) && isnothing(conn.timeout)
        h = hopen(conn.host, conn.port, conn.user)
    elseif (!isnothing(conn.user)) && (!isnothing(conn.timeout))
        h = hopen(conn.host, conn.port, conn.user, conn.timeout)
    end
    return KDBHandle(h)
end

function Base.open(f::Function, conn::KDBConnection)
    hobj = open(conn)
    return f(hobj)
    close!(hobj)
end

"""
    close!(conn::KDBHandle)

Close a connection to a KDB instance.
"""
function close!(c::KDBHandle)
    hclose(c.handle)
    c.isopen = false
end

isopen(c::KDBHandle) = c.isopen

"""
    execute(hobj::KDBHandle, query::AbstractString, args...)
    execute(conn::KDBConnection, query::AbstractString, args...)

Execute a query on a KDB instance via an open connection handle `hobj::KDBHandle`.
If the first argument is a `KDBConnection`, a temporary handle will be opened and closed automatically.
A query consists of a string and optional `args` which are sent to the KDB instance.

Examples:

```
    execute(hobj,"1+1")
    execute(hobj,"{x+y}", π-3, 3)
    execute(hobj,"{0N!x}","Hello from KDB!")
    execute(conn, "([] w:10?(0nj,til 3) ;x:10?1f ; y:10?(12;1b;`foo;\"bar\") ; z:10?`3)")
```
"""
function execute(hobj::KDBHandle, query::AbstractString, args...; async = false)
    # if not async, continue normally
    checkhandleok(hobj.handle)
    # convert args to K values and execute in kdb instance
    kargs_iter = ( upref!(convert_jl_to_k(x)).k for x in args)
    # result = K_lib.k(hobj.handle, query, kargs_iter..., K_lib.K_NULL)
    # convert back to native julia object
    if async
        result = K_lib.k(-hobj.handle, query, kargs_iter..., K_lib.K_NULL) # check send success?
        return nothing
    else
        result = K_lib.k(hobj.handle, query, kargs_iter..., K_lib.K_NULL)
        return access_value(K_Object(result))
    end
end

function execute(conn::KDBConnection, query::AbstractString, args...; async = false)
    hobj = open(conn)
    res = execute(hobj, query, args...; async=async)
    close!(hobj)
    return res
end
