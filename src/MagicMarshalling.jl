module MagicMarshalling

export marshal, unmarshal

using ArgCheck: @check, @argcheck
using ConstructionBase: constructorof, ConstructionBase

KEY_META = "__meta__"
KEY_CONSTRUCTOR = "constructor"
KEY_PROPERTYNAMES = "propertynames"
PKGNAME = "MagicMarshalling"

function __init__()
    # THIS IS HACKY
    # We do this so that ConstructionBase is visible in Main
    Core.eval(Main, :(using ConstructionBase: ConstructionBase))
end

constructor_string(o) = string(constructorof(typeof(o)))
constructor_string(::Tuple) = string(tuple)
constructor_string(o::Array) = string(reshape)

unmarshal(o::Vector) = map(unmarshal, o)
function marshal(o::Array)
    d = Dict{String, Any}()
    meta = Dict(
        KEY_CONSTRUCTOR => constructor_string(o),
        KEY_PROPERTYNAMES => ["data", "size"], # eltype?
    )
    d[KEY_META] = meta
    d["data"] = map(marshal, vec(o))
    d["size"] = marshal(size(o))
    d
end

function marshal_struct(o)
    d = Dict{String, Any}()
    meta = Dict(
        KEY_CONSTRUCTOR => constructor_string(o),
        KEY_PROPERTYNAMES => collect(map(string, propertynames(o))),
    )
    d[KEY_META] = meta
    for prop in propertynames(o)
        key = string(prop)
        d[key] = marshal(getproperty(o, prop))
    end
    d
end

marshal(o) = marshal_struct(o)

SelfMarshalTypes = Union{
    String, Int, Float64,
    }
marshal(o::SelfMarshalTypes) = o
unmarshal(o::SelfMarshalTypes) = o

function unmarshal(d::Dict)
    @argcheck haskey(d, KEY_META)
    meta = d[KEY_META]
    @check haskey(meta, KEY_CONSTRUCTOR)
    @check haskey(meta, KEY_PROPERTYNAMES)

    ctor_str = meta[KEY_CONSTRUCTOR]
    @check ctor_str isa String
    ctor_expr = nothing
    try
        ctor_expr = Meta.parse(ctor_str)
    catch err
        msg = """Error parsing constructor:
        string: $ctor_str
        error: $err
        """
        error(msg)
    end
    ctor = nothing
    try
        ctor = Core.eval(Main, ctor_expr)
    catch err
        msg = """Error evaluating constructor expression:
        string: $ctor_str
        expr: $ctor_expr
        error: $err
        """
        error(msg)
    end
    propnames = meta[KEY_PROPERTYNAMES]
    args = map(propnames) do key
        unmarshal(d[key])
    end
    ctor(args...)
end

end # module
