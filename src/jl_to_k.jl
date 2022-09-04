

# === Define Conversion Modes ===

abstract type KConvertMode end
struct KConvertAtom <: KConvertMode end
struct KConvertString <: KConvertMode end
struct KConvertVector <: KConvertMode end
struct KConvertDict <: KConvertMode end
struct KConvertTable <: KConvertMode end
struct KConvertUnknown <: KConvertMode end


# see below for specific conversion methods
const JuliaAtomTypes = Union{Real,AbstractChar,Dates.AbstractTime}

jl_to_kconvertmode(::T) where {T} = jl_to_kconvertmode(T)
jl_to_kconvertmode(::Type{<:Union{JuliaAtomTypes,Symbol}}) = KConvertAtom()
jl_to_kconvertmode(::Type{<:AbstractString}) = KConvertString()
jl_to_kconvertmode(::Type{<:AbstractArray}) = KConvertVector()
jl_to_kconvertmode(::Type{<:AbstractDict}) = KConvertDict()

function jl_to_kconvertmode(::Type{T}) where {T}
    if Tables.istable(T)
        return KConvertTable()
    elseif Base.isiterable(T)
        return KConvertVector()
    else
        return KConvertUnknown()
    end
end

convert_jl_to_k(x::K_Object) = x
convert_jl_to_k(x::T) where {T} = convert_jl_to_k(jl_to_kconvertmode(T), x)
convert_jl_to_k(::KConvertAtom, x) = jl_to_katom(x)
convert_jl_to_k(::KConvertString, x) = jl_to_kstring(x)
convert_jl_to_k(::KConvertVector, x) = jl_to_kvec(x)
convert_jl_to_k(::KConvertDict, x) = jl_to_dict(x)
convert_jl_to_k(::KConvertTable, x) = jl_to_table(x)


function convert_jl_to_k(::T, ::Type{KConvertUnknown}) where {T}
    error("Q.jl does not know how to convert type $T to a K_Object")
end


# === Converting Atoms to K Objects ===

jl_to_katom_type(::T) where {T} = jl_to_katom_type(T)
jl_to_katom_type(x::Type) = error("type $x) does not have an analogous atom type")
jl_to_katom_type(::Type{Bool}) = int_to_katomtype(1)
jl_to_katom_type(::Type{UInt8}) = int_to_katomtype(4)
jl_to_katom_type(::Type{Int16}) = int_to_katomtype(5)
jl_to_katom_type(::Type{Int32}) = int_to_katomtype(6)
jl_to_katom_type(::Type{Int64}) = int_to_katomtype(7)
jl_to_katom_type(::Type{<:Integer}) = int_to_katomtype(7)
jl_to_katom_type(::Type{Float32}) = int_to_katomtype(8)
jl_to_katom_type(::Type{Float64}) = int_to_katomtype(9)
jl_to_katom_type(::Type{<:AbstractFloat}) = int_to_katomtype(9)
jl_to_katom_type(::Type{Char}) = int_to_katomtype(10)
jl_to_katom_type(::Type{Symbol}) = int_to_katomtype(11)
jl_to_katom_type(::Type{Date}) = int_to_katomtype(14)
jl_to_katom_type(::Type{Time}) = int_to_katomtype(19)
jl_to_katom_type(::Type{<:Dates.AbstractTime}) = int_to_katomtype(19)
jl_to_katom_type(::Type{<:Dates.AbstractDateTime}) = int_to_katomtype(12)
jl_to_katom_type(::Type{TimeDate}) = int_to_katomtype(12)



# == Convert Julia object to C Type if necessary

# make sure String and Symbol are treated properly
jl_to_katom_cval(x) = x
jl_to_katom_cval(x::Date) = Dates.days(x - Date(2000))
jl_to_katom_cval(x::Time) = Dates.toms(x.instant)
jl_to_katom_cval(x::Dates.AbstractTime) = Dates.tons(x)
jl_to_katom_cval(x::T) where {T<:Union{Dates.AbstractDateTime,TimeDate}} = Dates.tons(x - T(Date(2000)))


# == Convert Julia object to K Object
jl_to_katom(x::T) where {T} = jl_to_katom(x, jl_to_katom_type(T))
function jl_to_katom(x, kt::KAtomType)
    return new_katom(jl_to_katom_cval(x), kt)
end

# == Convert JL object to C Type if necessary

jl_to_katomvec_cval(x) = x

function jl_to_katomvec_cval(x::AbstractVector{T}) where {T<:Union{Time,Date,TimeDate,Dates.AbstractDateTime}}
    jl_to_katom_cval.(x)
end

# === Convert Julia Strings to K_Objects

jl_to_kstring(x::AbstractString) = K_Object(K_lib.kp(x))

# == Converting Vectors and Arrays to K Objects ==

# Notes: cases:
# 1 - Vector{T}, where T<: JlAtomTypes
# 2 - Finite 1D iterable with T <: JlAtomTypes 
# 3 - Finite ND iterable with T <: JlAtomTypes -> project to slices
# 4 - Everything else shoved into mixed vectors

# get iterator element type and size
jl_to_kvec(iter::T) where {T} = jl_to_kvec(iter, IteratorSize(T), eltype(T))

# case of atomic vector with "atomic" elements
function jl_to_kvec(iter::Vector{T}, ::HasLength, ::Type{T}) where {T<:JuliaAtomTypes}
    # Get atom type info
    KT = jl_to_katom_type(T)
    C = katom_ctype(KT)
    i = katom_typeint(KT)
    # Fill new K vector
    n = length(iter)
    k_obj = K_Object(K_lib.ktn(i, n))
    unsafe_copyto!(Ptr{C}(k_obj.k + 16), pointer(Vector{C}(jl_to_katomvec_cval(iter))), n)
    return k_obj
end

# case of vector-like iterator of "atomic" elements
function jl_to_kvec(iter, ::HasLength, ::Type{T}) where {T<:JuliaAtomTypes}
    # Get atom type info
    KT = jl_to_katom_type(T)
    i = katom_typeint(KT)
    C = katom_ctype(KT)
    # Fill new K vector
    k_obj = K_Object(K_lib.ktn(i, length(iter)))
    for (i, z) in enumerate(iter)
        unsafe_store!(Ptr{C}(k_obj.k + 16), C(jl_to_katom_cval(z)), i)
    end
    return k_obj
end

# case of vector-like iterator of "atomic" elements and missings
function jl_to_kvec(iter, ::HasLength, ::Type{Union{T,Missing}}) where {T<:JuliaAtomTypes}
    # Get atom type info
    KT = jl_to_katom_type(T)
    i = katom_typeint(KT)
    C = katom_ctype(KT)
    # Get missing value to fill with
    missing_val = katom_ctype_missingval(C)
    # Fill new K vector
    k_obj = K_Object(K_lib.ktn(i, length(iter)))
    for (i, z) in enumerate(iter)
        fillval = coalesce(jl_to_katom_cval(z), missing_val)
        unsafe_store!(Ptr{C}(k_obj.k + 16), C(fillval), i)
    end
    return k_obj
end

# case of vector-like iterator of Symbols
function jl_to_kvec(iter, ::HasLength, ::Type{Symbol})
    k_obj = K_lib.ktn(K_lib.KS, length(iter)) |> K_Object
    for (i, x) in enumerate(iter)
        unsafe_store!(Ptr{K_lib.S}(k_obj.k + 16), K_lib.ss(x), i)
    end
    return k_obj
end

# case of vector-like iterator of Symbols and missings
function jl_to_kvec(iter, ::HasLength, ::Type{Union{Symbol,Missing}})
    new_iter = Missings.replace(iter, Symbol())
    return jl_to_kvec(new_iter, HasLength(), Symbol)
end

# case of String/Missing Vector
function jl_to_kvec(iter, ::HasLength, ::Type{Union{String,Missing}})
    new_iter = Missings.replace(iter, "")
    return jl_to_kvec(new_iter, HasLength(), String)
end

# case of multi-dimensional iterator
function jl_to_kvec(iter, ::HasShape{N}, typ::Type) where {N}
    (N === 1) && return jl_to_kvec(iter, HasLength(), typ)
    slice_iter = eachslice(iter, dims=1)
    return jl_to_kvec(slice_iter, HasLength(), Any) # pass slice iter to generic mixed list constructor
end

# case of generic mixed vector
# function jl_to_kvec(iter, ::HasLength, ::Type)
#     n = length(iter)
#     k_obj = K_Object(K_lib.ktn(0, n))
#     for (i, x) in enumerate(iter)
#         elem_k_obj = convert_jl_to_k(x) # increase ref count so that ownership is transferred
#         unsafe_store!(Ptr{K_lib.K}(k_obj.k + 16), upref!(elem_k_obj).k, i)
#     end
#     return k_obj
# end

function jl_to_kvec(iter, ::HasLength, ::Type)
    n = length(iter)
    k_obj = K_Object(K_lib.ktn(0, n))
    for (i, x) in enumerate(iter)
        elem_k_obj = convert_jl_to_k(x) # increase ref count so that ownership is transferred
        unsafe_store!(Ptr{K_lib.K}(k_obj.k + 16), upref!(elem_k_obj).k, i)
    end
    return k_obj
end


jl_to_kvec(_, T::Union{IsInfinite,SizeUnknown}, _) = error("Q.jl error: Cannot convert an iterator with IteratorSize $T to K_Object")

# === Converting Dictionaries to K Objects ===

keys2sym(k::T) where {T} = keys2sym(eltype(T), k)
keys2sym(::Type{Symbol}, k) = k
keys2sym(::Type{T}, k) where {T} = Symbol.(k)

function jl_to_dict(dict::AbstractDict)
    keys_obj = convert_jl_to_k(keys(dict) |> keys2sym)
    values_obj = convert_jl_to_k(values(dict))
    return K_lib.xD(upref!(keys_obj).k, upref!(values_obj).k) |> K_Object
end

# === Converting Tables to K Objects ===

# converts any Tables.jl interface
function jl_to_table(table)
    colnames = convert_jl_to_k(Tables.columnnames(table))
    coldata = jl_to_kvec(Tables.columns(table))
    return K_lib.xD(upref!(colnames).k, upref!(coldata).k) |> K_lib.xT |> K_Object
end
