
"""
    K_Object(k::K_lib.K)

Julia wrapper of K Object.
This wrapper ensures that the K_Object is garbage collected.
"""
mutable struct K_Object
    k::K_lib.K
    function K_Object(k::K_lib.K)
        # increment refcount
        obj = new(k)
        finalizer(obj) do o
            K_lib.r0(o.k) # decrement refcount
        end
    end
end

ktypeint(k::K_lib.K) = K_lib.xt(k)
refcount(k::K_lib.K) = K_lib.xr(k)

ktypeint(x::K_Object) = ktypeint(x.k)
refcount(x::K_Object) = refcount(x.k)

function upref!(obj::K_Object)
    obj.k = K_lib.r1(obj.k)
    return obj
end

function downref!(obj::K_Object)
    obj.k = K_lib.r0(obj.k)
    return obj
end

function Base.show(io::IO, ::MIME"text/plain", x::K_Object)
    type_num = ktypeint(x)
    print(io, "K_Object( type=$type_num, refcount=$(refcount(x)))")
end

# === K Atomic Types

"""
    KAtomType{I,C,Jl}

 - I represents the integer code for the k type, 
 - C represents the corresponding C type
 - Jl represents the julia type to be converted to by default.
"""
struct KAtomType{I,TC,TJ} end

# Store the known atomic types
# TODO: turn these into instances
const ATOM_TYPES = (
    KAtomType{1,K_lib.G,Bool}(),
    KAtomType{2,K_lib.U,UInt128}(), # not yet implemented
    nothing,
    KAtomType{4,K_lib.G,UInt8}(),
    KAtomType{5,K_lib.H,Int16}(),
    KAtomType{6,K_lib.I,Int32}(),
    KAtomType{7,K_lib.J,Int64}(),
    KAtomType{8,K_lib.E,Float32}(),
    KAtomType{9,K_lib.F,Float64}(),
    KAtomType{10,K_lib.G,Char}(),
    KAtomType{11,K_lib.S,Symbol}(),
    KAtomType{12,K_lib.J,NanoDate}(),
    KAtomType{13,K_lib.I,Date}(),
    KAtomType{14,K_lib.I,Date}(),
    KAtomType{15,K_lib.F,NanoDate}(),
    KAtomType{16,K_lib.J,Time}(),
    KAtomType{17,K_lib.I,Minute}(),
    KAtomType{18,K_lib.I,Second}(),
    KAtomType{19,K_lib.I,Time}(),
)

@inline int_to_katomtype(i::Integer) = ATOM_TYPES[i]
katom_ctype(::KAtomType{<:Any,C,<:Any}) where {C} = C
katom_jltype(::KAtomType{<:Any,<:Any,Jl}) where {Jl} = Jl
katom_typeint(::KAtomType{I,<:Any,<:Any}) where {I} = I

# === Define Missing Type Conversions
KAtomTypesWithMissing = Union{K_lib.H, K_lib.I, K_lib.J, K_lib.E, K_lib.F}
# katom_ctype_missingval(::Type{K_lib.G}) = K_lib.G(' ')
katom_ctype_missingval(::Type{K_lib.H}) = K_lib.nh
katom_ctype_missingval(::Type{K_lib.I}) = K_lib.ni
katom_ctype_missingval(::Type{K_lib.J}) = K_lib.nj
katom_ctype_missingval(::Type{K_lib.E}) = K_lib.ne
katom_ctype_missingval(::Type{K_lib.F}) = K_lib.nf

# == String tuple representation of each K Atom type
katom_string(i::Integer) = katom_string(ATOM_TYPES[i])
katom_string(::KAtomType) = ('k', "k_object")
katom_string(::KAtomType{1}) = ('b', "boolean")
katom_string(::KAtomType{2}) = ('g', "guid") # TODO: GUID support
katom_string(::KAtomType{4}) = ('x', "byte")
katom_string(::KAtomType{5}) = ('h', "short")
katom_string(::KAtomType{6}) = ('i', "int")
katom_string(::KAtomType{7}) = ('j', "long")
katom_string(::KAtomType{8}) = ('e', "real")
katom_string(::KAtomType{9}) = ('f', "float")
katom_string(::KAtomType{10}) = ('c', "char")
katom_string(::KAtomType{11}) = ('s', "symbol")
katom_string(::KAtomType{12}) = ('p', "timestamp")
katom_string(::KAtomType{13}) = ('m', "month")
katom_string(::KAtomType{14}) = ('d', "date")
katom_string(::KAtomType{15}) = ('z', "datetime")
katom_string(::KAtomType{16}) = ('n', "timespan")
katom_string(::KAtomType{17}) = ('u', "minute")
katom_string(::KAtomType{18}) = ('v', "second")
katom_string(::KAtomType{19}) = ('t', "time")


# == C Value Accessor Methods for Atoms
function access_katom_cval(k::K_lib.K, ::KAtomType{<:Any,CT,<:Any}) where {CT<:K_lib.K_CTypes}
    access_katom_cval(k, CT)
end

access_katom_cval(k::K_lib.K, ::Type{K_lib.G}) = K_lib.xg(k)
access_katom_cval(k::K_lib.K, ::Type{K_lib.H}) = K_lib.xh(k)
access_katom_cval(k::K_lib.K, ::Type{K_lib.I}) = K_lib.xi(k)
access_katom_cval(k::K_lib.K, ::Type{K_lib.J}) = K_lib.xj(k)
access_katom_cval(k::K_lib.K, ::Type{K_lib.E}) = K_lib.xe(k)
access_katom_cval(k::K_lib.K, ::Type{K_lib.F}) = K_lib.xf(k)
access_katom_cval(k::K_lib.K, ::Type{K_lib.S}) = K_lib.xs(k)


# == C Value Accessor Methods for Atomic Vectors

access_kstring(k::K_lib.K) = K_lib.xp(k)

function access_katomvec_cval(k::K_lib.K, ::KAtomType{<:Any,CT,<:Any}) where {CT<:K_lib.K_CTypes}
    access_katom_cval(k, CT)
end

access_katomvec_cval(k::K_lib.K, ::Type{K_lib.C}) = K_lib.xp(k) # already copies
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.G}) = K_lib.kG(k) |> copy
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.H}) = K_lib.kH(k) |> copy
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.I}) = K_lib.kI(k) |> copy
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.J}) = K_lib.kJ(k) |> copy
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.E}) = K_lib.kE(k) |> copy
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.F}) = K_lib.kF(k) |> copy
access_katomvec_cval(k::K_lib.K, ::Type{K_lib.S}) = K_lib.kS(k) |> copy


# == New C/K Value Initialization for K Atoms

new_katom(c_val, i::Integer) = new_katom(c_val, int_to_katomtype(i))
new_katom(c_val, ::KAtomType{1}) = K_lib.kb(c_val) |> K_Object
# new_katom(c_val, ::KAtomType{2}) = K_lib.kg(c_val) |> K_Object
new_katom(c_val, ::KAtomType{4}) = K_lib.kg(c_val) |> K_Object
new_katom(c_val, ::KAtomType{5}) = K_lib.kh(c_val) |> K_Object
new_katom(c_val, ::KAtomType{6}) = K_lib.ki(c_val) |> K_Object
new_katom(c_val, ::KAtomType{7}) = K_lib.kj(c_val) |> K_Object
new_katom(c_val, ::KAtomType{8}) = K_lib.ke(c_val) |> K_Object
new_katom(c_val, ::KAtomType{9}) = K_lib.kf(c_val) |> K_Object
new_katom(c_val, ::KAtomType{10}) = K_lib.kc(c_val) |> K_Object
new_katom(c_val, ::KAtomType{11}) = K_lib.ks(c_val) |> K_Object
new_katom(c_val, ::KAtomType{12}) = K_lib.ktj(-12, c_val) |> K_Object
new_katom(c_val, ::KAtomType{13}) = K_lib.km(c_val) |> K_Object
new_katom(c_val, ::KAtomType{14}) = K_lib.kd(c_val) |> K_Object
new_katom(c_val, ::KAtomType{15}) = K_lib.kz(c_val) |> K_Object
new_katom(c_val, ::KAtomType{16}) = K_lib.ktj(-16, c_val) |> K_Object # no kx, for some reason
new_katom(c_val, ::KAtomType{17}) = K_lib.ku(c_val) |> K_Object
new_katom(c_val, ::KAtomType{18}) = K_lib.ktj(-18, c_val) |> K_Object
new_katom(c_val, ::KAtomType{19}) = K_lib.kt(c_val) |> K_Object

# == New C/K Value Initialization for K Vectors

new_katomvec(x) = new_katomvec(x, int_to_katomtype(i))

function new_katomvec(x::Vector{T}, ::KAtomType{I,C}) where {I,C,T}
    n = length(x)
    x = K_lib.ktn(abs(I), n)
    unsafe_copy!(Ptr{C}(x + 16), pointer(jl_value_to_katomvec_cval(x)), n)
    return K_Object(x)
end
