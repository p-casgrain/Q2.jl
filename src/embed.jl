

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
    _cfn = @cfunction(KdbConnect._eval_string_noreturn, KdbConnect.K_lib.K, (KdbConnect.K_lib.K,))
    _kfn = K_lib.dl(_cfn, 1)
    K_lib.k(0, "{.J.e:x}",_kfn,K_lib.K_NULL) |> K_lib.r0

    # eval string
    _cfn = @cfunction(KdbConnect._eval_string_return, KdbConnect.K_lib.K, (KdbConnect.K_lib.K,))
    _kfn = K_lib.dl(_cfn, 1)
    K_lib.k(0, "{.J.er:x}",_kfn,K_lib.K_NULL) |> K_lib.r0

    # function wrapper
    _cfn = @cfunction(KdbConnect._eval_function, KdbConnect.K_lib.K, (KdbConnect.K_lib.K,KdbConnect.K_lib.K,))
    _kfn = KdbConnect.K_lib.dl(_cfn, 2)
    KdbConnect.K_lib.k(0, "{.J.u_.J_fn_wrap:x}", _kfn, K_lib.K_NULL) |> K_lib.r0

    # set variable
    _cfn = @cfunction(KdbConnect._set , KdbConnect.K_lib.K, (KdbConnect.K_lib.K,KdbConnect.K_lib.K,))
    _kfn = KdbConnect.K_lib.dl(_cfn, 2)
    KdbConnect.K_lib.k(0, "{.J.set:x}", _kfn, K_lib.K_NULL) |> K_lib.r0


    return nothing
end

#TODO: qeval macro --> runs version of "execute"
#TODO: only text eval macro --> never returns


