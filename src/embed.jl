
iscallable(f) = !isempty(methods(f)) | isa(f, Function)
isdefaultktype(x::T) where {T} = isdefaultktype(Type{T})
isdefaultktype(::Type{T}) where {T} = isprimitivetype(T) | istable(T) | isiterable(T)
isdefaultktype(::Type{T}) where {T<:Union{String,Symbol,Number,Char,Array,Vector,Dict}} = true

function K_function_wrap_(fn)::Function
    return function(kin)
        try
            return convert_jl_to_k(fn(access_value(K_obj(kin))...)).k :: K_lib.K
        catch err
            return K_lib.krr("julia error: " * string(err)) :: K_lib.K
        end
    end
end

function _eval_string(x::K_lib.K)::K_lib.K
    # println(K_lib.xp(x))
    if K_lib.xt(x) != K_lib.KC
        return K_lib.krr("type")
    end

    v = try
        eval(Meta.parse(K_lib.xp(x)))
    catch err
        return K_lib.krr("julia error: " * string(err))
    end

    p = try
        convert_jl_to_k(v).k
    catch err
        println("jl→k error: cannot convert Type{$(string(typeof(v)))}")
        return K_lib.K_NULL
    end

    return p
end

function _wrap_function(x::K_lib.K)::K_lib.K
    if K_lib.xt(x) != KC
        return K_lib.krr("type")
    end

    v = try
        eval(parse(K_lib.xp(x)))
    catch err
        return K_lib.krr("julia error: " * string(err))
    end

    p = try 
        begin
            f = K_function_wrap_(v)
            Q2.K_lib.dl(@cfunction($f,K_lib.K,(K_lib.K,)),1)
        end
    catch err
        return K_lib.krr("jl→k(fnwrap) error: " * string("K_obj:", err))
    end

    return p
end


function __init__()
    global _eval_string_c = @cfunction(Q2._eval_string, Q2.K_lib.K, (Q2.K_lib.K,))
    # global _wrap_function_c = @cfunction(Q2._wrap_function, Q2.K_lib.K, (Q2.K_lib.K,))
    Q2.K_lib.k(0, "{.J.e::x}", Q2.K_lib.dl(_eval_string_c, 1))
    # Q2.K_lib.k(0, "{.J.wrapfn::x}", Q2.K_lib.dl(_wrap_function_c, 1))
    return nothing
end


#TODO: qeval macro --> runs version of "execute"
#TODO: only text eval macro --> never returns


