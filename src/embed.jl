

function _eval_function(fn_name_str_::K_lib.K,args_list_::K_lib.K)::K_lib.K
    
    if K_lib.xt(fn_name_str_) != K_lib.KC
        return K_lib.krr("type")
    end

    if !( 0 <= K_lib.xt(args_list_) < 19 )
        return K_lib.krr("length")
    end

    fn = try
        eval(Meta.parse(REPL.softscope(K_lib.xp(fn_name_str_))))
    catch err
        return K_lib.krr("fn_name parse error: $err")
    end

    args_list = try
        access_value(upref!(K_Object(args_list_)))
    catch err
        println(err)
        return K_lib.krr("q→jl error: $err")
    end

    popfirst!(args_list)

    res = try
        convert_jl_to_k(fn(args_list...))
    catch err
        # println(err)
        show(stdout,MIME"text/plain"(),err)
        return K_lib.krr("julia function error: $err")
    end
    
    return upref!(res).k::K_lib.K
end

function _eval_string_return(x::K_lib.K)::K_lib.K
    # println(K_lib.xp(x))
    if K_lib.xt(x) != K_lib.KC
        return K_lib.krr("type")
    end
    v = try
        eval(Meta.parse(REPL.softscope(K_lib.xp(x))))
    catch err
        return K_lib.krr("julia error: $err")
    end

    p = try
        upref!(convert_jl_to_k(v)).k
    catch err
        return K_lib.krr("jl→q error: $err")
    end

    return p
end

function _eval_string_noreturn(x::K_lib.K)::K_lib.K
    if K_lib.xt(x) != K_lib.KC
        return K_lib.krr("type")
    end

    res = try
        eval(Meta.parse(REPL.softscope(K_lib.xp(x))))
    catch err
        println("Julia Error: $err")
        return K_lib.krr("julia")
    end

    try
        show(stdout,MIME"text/plain"(),res)
        print("\n")
    catch err
        println("Julia Error: $err")
        return K_lib.krr("julia_print")
    end

    return K_lib.K_NULL
end

macro q(sym)
    quote
        K_lib.k(0, $(string(sym)), K_lib.K_NULL) |> K_Object |> access_value
    end
end

function dictsubeval(s, dict)
    pattern = r"@q\(([^)]+)\)"
    processed = replace(s, pattern => m -> begin
        var_name = Symbol(match(pattern, m).captures[1])
        haskey(dict, var_name) ? "$(dict[var_name])" : m
    end)
    return processed
end

function _eval_string_args(eval_str_::K_lib.K,args_::K_lib.K)::K_lib.K

    # load string and options
    if K_lib.xt(eval_str_) != K_lib.KC
        return K_lib.krr("type")
    else
        eval_str = K_lib.xp(eval_str_)
    end

    args_dict = try
        if K_lib.xt(args_) == 99
            access_value(upref!(K_Object(args_)))
        else
            Dict{Symbol,Bool}()
        end
    catch
        return K_lib.krr("load_options")
    end

    v = try
        dictsubeval(eval_str,args_dict)
    catch err
        return K_lib.krr("julia error: $err")
    end

    p = try
        upref!(convert_jl_to_k(v)).k
    catch err
        return K_lib.krr("jl→q error: $err")
    end
    
    return p
end

function _set(var_str_::K_lib.K,val_::K_lib.K)
    if K_lib.xt(var_str_) == K_lib.KC
        var_sym = Symbol(K_lib.xp(var_str_))
    elseif K_lib.xt(var_str_) == -K_lib.KS
        var_sym = access_value(upref!(K_Object(var_str_)))
    else
        return K_lib.krr("type")
    end

    try
        v = access_value(upref!(K_Object(val_)))
        eval(:($var_sym = $v))
    catch err
        show(err)
        return K_lib.krr("julia_eval")
    end

    return K_lib.K_NULL
end

function __init__()
    
    # eval string
    _cfn = @cfunction(Q2._eval_string_noreturn, Q2.K_lib.K, (Q2.K_lib.K,))
    _kfn = K_lib.dl(_cfn, 1)
    K_lib.k(0, "{.J.e:x}",_kfn,K_lib.K_NULL) |> K_lib.r0

    # eval string
    _cfn = @cfunction(Q2._eval_string_return, Q2.K_lib.K, (Q2.K_lib.K,))
    _kfn = K_lib.dl(_cfn, 1)
    K_lib.k(0, "{.J.er:x}",_kfn,K_lib.K_NULL) |> K_lib.r0

    # function wrapper
    _cfn = @cfunction(Q2._eval_function, Q2.K_lib.K, (Q2.K_lib.K,Q2.K_lib.K,))
    _kfn = Q2.K_lib.dl(_cfn, 2)
    Q2.K_lib.k(0, "{.J.u_.J_fn_wrap:x}", _kfn, K_lib.K_NULL) |> K_lib.r0

    # advanced eval_str
    _cfn = @cfunction(Q2._eval_string_args, Q2.K_lib.K, (Q2.K_lib.K,Q2.K_lib.K,))
    _kfn = Q2.K_lib.dl(_cfn, 2)
    Q2.K_lib.k(0, "{.J.eo:x}", _kfn, K_lib.K_NULL) |> K_lib.r0

    # set variable
    _cfn = @cfunction(Q2._set , Q2.K_lib.K, (Q2.K_lib.K,Q2.K_lib.K,))
    _kfn = Q2.K_lib.dl(_cfn, 2)
    Q2.K_lib.k(0, "{.J.set:x}", _kfn, K_lib.K_NULL) |> K_lib.r0

    
    # # function wrapper v2
    # _cfn = @cfunction(Q2._load_function, Q2.K_lib.K, (Q2.K_lib.K,))
    # _kfn = Q2.K_lib.dl(_cfn, 1)
    # Q2.K_lib.k(0, "{.J.loadfn:x}", _kfn, K_lib.K_NULL) |> K_lib.r0

    return nothing
end

#TODO: qeval macro --> runs version of "execute"
#TODO: only text eval macro --> never returns


