

# == General Value Access Method

access_value(x::K_Object) = access_value(x.k)

function access_value(k_ptr::K_lib.K)
    type_int = ktypeint(k_ptr)
    if -19 <= type_int < 0 # type is atom
        katomtype = int_to_katomtype(abs(type_int))
        return access_atom(k_ptr, katomtype)
    elseif type_int == 10 # type is a string
        return access_kstring(k_ptr)
    elseif 0 < type_int <= 19 # type is atomic vector
        katomtype = ATOM_TYPES[abs(type_int)]
        return access_atom_vec(k_ptr, katomtype)
    elseif type_int == 0 # type is mixed vector
        access_mixed_vec(k_ptr)
    elseif type_int == 98 # type is table
        access_table(k_ptr)
    elseif type_int == 99 # type is a dict
        access_dict(k_ptr)
    elseif type_int == -128 # type is an error
        error_str = K_lib.xs(k_ptr)
        # TODO: make a Q error type
        error("q error: '" * error_str)
    elseif type_int in 77:112 # is a function or primitive
        return nothing
    else
        return error("Unsupported K type integer $type_int")
    end
end

# == Conversion from C types into Julia types

# treat case of missings depending on C type
convert_katom_cval(cval, t::KAtomType) = _convert_katom_cval(cval,t)

function convert_katom_cval(cval, t::KAtomType{11})
    (cval === "") && return missing
    return _convert_katom_cval(cval, t)
end

function convert_katom_cval(cval, t::KAtomType{<:Any,T}) where {T<:KAtomTypesWithMissing}
    (cval === katom_ctype_missingval(T)) && return missing
    return _convert_katom_cval(cval, t)
end


_convert_katom_cval(cval, ::KAtomType) = cval

# naive conversion for some types
const KTypeNaiveAtomConvert = Union{Bool,Symbol,Char,Minute,Second}
_convert_katom_cval(cval, ::KAtomType{<:Any,<:Any,Jl}) where {Jl<:KTypeNaiveAtomConvert} = Jl(cval)

# custom conversion for date and time types
_convert_katom_cval(ns::K_lib.J, ::KAtomType{12}) = TimeDate(2000) + Nanosecond(ns)
_convert_katom_cval(nmonths::K_lib.I, ::KAtomType{13}) = Date(2000) + Month(nmonths)
_convert_katom_cval(ndays::K_lib.I, ::KAtomType{14}) = Date(2000) + Day(ndays)
_convert_katom_cval(df::K_lib.F, ::KAtomType{15}) = TimeDate(2000) + Day(floor(df)) + Nanosecond(floor(mod(df, 1) * NANOSECONDSPERDAY))
_convert_katom_cval(ns::K_lib.J, ::KAtomType{16}) = Time(0) + Nanosecond(ns)
_convert_katom_cval(ms::K_lib.I, ::KAtomType{19}) = Time(0) + Millisecond(ms)

# == Conversion for vectors

# no conversion by default
convert_katom_cvec(cvec, ::KAtomType) = cvec

function convert_katom_cvec(cvec, t::KAtomType{11}) # symbol vector conversion
    return [convert_katom_cval(unsafe_string(x),t) for x in cvec]
end

const KTypeNaiveVectorConvertNoMissing = Union{Symbol,Char} # for these, broadcast atom conversion
# const KTypeNaiveVectorConvertWithMissing = Union{Minute,Second,TimeDate,NanoDate,Date,Time}

function convert_katom_cvec(cvec, t::KAtomType{<:Any,<:Any,JT}) where {JT<:KTypeNaiveVectorConvertNoMissing}
    return JT[convert_katom_cval(x, t) for x in cvec]
end

function convert_katom_cvec(cvec, t::KAtomType{<:Any,T}) where {T<:KAtomTypesWithMissing}
    return [convert_katom_cval(x, t) for x in cvec]
end

# == Atom / Vector Value Access Functions

function access_atom(k_ptr::K_lib.K, k_type::KAtomType)
    c_val = access_katom_cval(k_ptr, k_type)
    return convert_katom_cval(c_val, k_type)
end

function access_atom_vec(k_ptr::K_lib.K, k_type::KAtomType)
    c_vec = access_katomvec_cval(k_ptr, katom_ctype(k_type))
    return convert_katom_cvec(c_vec, k_type)
end

function access_mixed_vec(k_ptr::K_lib.K)
    k_vec = K_lib.kK(k_ptr) # a vector of K_lib.k objects
    return access_value.(k_vec)
end

# == Access Dictionary

function access_dict(k_ptr::K_lib.K)
    key_k, value_k = K_lib.kK(k_ptr) # 2-elem vec K_lib.k objects
    key_type = ktypeint(key_k)
    if key_type == 11 # it's a standard dictionary
        key_jl, value_jl = access_value(key_k), access_value(value_k)
        return Dict(Iterators.zip(key_jl, value_jl))
    elseif key_type == 98 # it's a keyed table
        return access_keyed_table(key_k, value_k)
    else
        error("Q Error: Unknown dictionary key type $key_type")
    end
end

# == Access Table

function access_table(k_ptr::K_lib.K)
    newptr = unsafe_load(k_ptr.k)
    key_k, value_k = K_lib.kK(newptr) # 2-elem vec K_lib.k objects
    key_jl, value_jl = access_value(key_k), access_value(value_k)
    return (; zip(key_jl, value_jl)...) # returns NamedTuple
end


# == Access Keyed Table

function access_keyed_table(key_k_ptr::K_lib.K, value_k_ptr::K_lib.K)
    # Load the key data
    newptr0 = unsafe_load(key_k_ptr.k)
    key_k0, value_k0 = K_lib.kK(newptr0) # 2-elem vec K_lib.k objects
    key_jl0, value_jl0 = access_value(key_k0), access_value(value_k0)
    # Load the value data
    newptr1 = unsafe_load(value_k_ptr.k)
    key_k1, value_k1 = K_lib.kK(newptr1) # 2-elem vec K_lib.k objects
    key_jl1, value_jl1 = access_value(key_k1), access_value(value_k1)
    # Jam it into a K_Table object
    key_iter = flatten((key_jl0, key_jl1))
    val_iter = flatten((value_jl0, value_jl1))
    return (; zip(key_iter, val_iter)...) # returns NamedTuple
end

