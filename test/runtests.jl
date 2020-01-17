using MagicMarshalling
using Test

is_simple_type(o) = false
is_simple_type(o::Int) = true
is_simple_type(o::Float64) = true
is_simple_type(o::String) = true

function is_simple_type(o::Vector)
    for x in o
        is_simple_type(x) || return false
    end
    return true
end
function is_simple_type(o::Dict)
    for (k,v) in pairs(o)
        k isa String || return false
        is_simple_type(v) || return false
    end
    return true
end

@testset "Basic bitstypes" begin
    for o in [1,1.0,-2,NaN,-Inf,]
        m = marshal(o)
        @test is_simple_type(m)
        o2 = unmarshal(m)
        @test o === o2
    end
end

@testset "NamedTuple" begin
    o = (a=1, b=2)
    m = marshal(o)
    @test is_simple_type(m)
    o2 = unmarshal(m)
    @test o === o2
end

@testset "Tuple $o" for o in [(), (1,), (1,2), ((1,2), (3,4))]
    m = marshal(o)
    @test is_simple_type(m)
    o2 = unmarshal(m)
    @test o === o2
end

@testset "Array" begin
    for o in [
                [1,2],
                [1 2; 3 4],
                ["a", 2],
                [],
                [[1]],
                [[1], [1,[3]]],
        ]
        m = marshal(o)
        @test is_simple_type(m)
        o2 = unmarshal(m)
        @test o == o2
    end
end

@testset "Structs" begin
    struct ParametricStruct{A,B}
        a::A
        b::B
    end

    for o in [
        ParametricStruct(1,2),
        ParametricStruct(ParametricStruct(1,2), ParametricStruct(1.0, 3)),
       ]
        m = marshal(o)
        @test is_simple_type(m)
        o2 = unmarshal(m)
        @test o === o2
    end
end
