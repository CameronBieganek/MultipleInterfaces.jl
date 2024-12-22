

module IntersectionTests

using Test
using ExtendableInterfaces


function a end
function b end
function h end

@interface A begin
    a
end

@interface B begin
    b
end

# Isolated node in interface DAG.
@interface H begin
    h
end

@interface C extends A, B
@interface D extends B
@interface E extends C, D
@interface F extends E
@interface G extends F


@testset "interface intersections" begin
    @test A & A == A
    @test A & A & A == A
    @test E & E == E
    @test E & E & E == E
    @test H & H == H
    @test H & H & H == H

    @test A & B != A & C
    @test A & H != B & D

    @test A & B == B & A
    @test E & F == F & E
    @test (
        E & F & G ==
        E & G & F ==
        F & G & E ==
        F & E & G ==
        G & E & F ==
        G & F & E
    )

    @test A & B & C == C
    @test A & B & C & D == C & D == D & C
    @test A & B & C & D & H == C & D & H
    @test A & B & C & D & H & A == C & D & H

    @test E & F == F
    @test E & F & G == G
    @test E & F & G & H == G & H
end

end
