

module IntersectionEqualityTests

using Test
using ExtendableInterfaces


function a end
function b end
function h end
function i end

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

# Isolated node in interface DAG.
@interface I begin
    i
end

@interface C extends A, B
@interface D extends B
@interface E extends C, D
@interface F extends E
@interface G extends F


@testset "interface intersections equality" begin
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

    @test A & B & B & A == A & B == B & A
    @test B & B & A & A == A & B == B & A
    @test C & A & B & B & A & C == A & B & C == C & B & A

    # These tests check the `Base.:&(s::Intersection, t::Intersection)` method:
    @test (A & B) & (H & I) == A & B & H & I
    @test (A & B) & (H & A) == A & B & H
    @test (A & B) & (A & B) == A & B
    @test (A & B) & (B & A) == A & B
end

end



module IntersectionSubinterfaceTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: remove_superinterfaces, most_specific, SingleArgumentAmbiguity


function a end
function b end
function c end
function d end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end
@interface D extends C begin d end

function k end
function l end

@interface K begin k end
@interface L extends K begin l end

function p end
function q end

@interface P begin p end
@interface Q extends P begin q end

function x end
function y end

@interface X begin x end
@interface Y extends X begin y end


@testset "interface intersections `is_subinterface`" begin

    @test K & P ≼ K & P
    @test K & P ≼ P & K
    @test P & K ≼ K & P

    @test K & P & X ≼ K & P & X
    @test K & P & X ≼ P & K & X
    @test K & P & X ≼ P & X & K
    @test P & K & X ≼ K & P & X
    @test K & P & X ≼ K & P & X
    @test X & K & P ≼ K & P & X

    @test K & P & X & P ≼ K & P & X
    @test K & P & X ≼ K & P & X & K
    @test P & K & X & X ≼ K & P & X
    @test P & K & X ≼ K & P & X & P

    @test A & K ≼ A
    @test A & K ≼ K
    @test A & K ⋠ P
    @test A ⋠ A & K
    @test K ⋠ A & K
    @test P ⋠ A & K

    @test A & K & P ≼ A
    @test A & K & P ≼ K
    @test A & K & P ≼ P
    @test A & K & P ⋠ X
    @test A ⋠ A & K & P
    @test K ⋠ A & K & P
    @test P ⋠ A & K & P
    @test X ⋠ A & K & P

    @test C & K ≼ A & K
    @test D & K ≼ A & K
    @test A & L ≼ A & K
    @test C & L ≼ A & K
    @test D & L ≼ A & K
    @test A & K ⋠ C & K
    @test A & K ⋠ D & K
    @test A & K ⋠ A & L
    @test A & K ⋠ C & L
    @test A & K ⋠ D & L

    @test K & P & X ≼ K & P
    @test X & K & P ≼ P & K
    @test K & P ⋠ K & P & X
    @test P & K ⋠ X & K & P

    @test L & P & X ≼ K & P
    @test K & Q & X ≼ K & P
    @test L & Q & X ≼ K & P
    @test L & Q & Y ≼ K & P
    @test L & Q & A ≼ K & P

    @test K & P ⋠ L & P & X
    @test K & P ⋠ K & Q & X
    @test K & P ⋠ L & Q & X
    @test K & P ⋠ L & Q & Y
    @test K & P ⋠ L & Q & A

    @test A & K & P & X ≼ K & P & X
    @test B & K & P & X ≼ K & P & X
    @test C & K & P & X ≼ K & P & X
    @test A & L & P & X ≼ K & P & X
    @test A & K & Q & X ≼ K & P & X
    @test A & K & P & Y ≼ K & P & X

    @test K & P & X ⋠ A & K & P & X
    @test K & P & X ⋠ B & K & P & X
    @test K & P & X ⋠ C & K & P & X
    @test K & P & X ⋠ A & L & P & X
    @test K & P & X ⋠ A & K & Q & X
    @test K & P & X ⋠ A & K & P & Y

    @test K & Q ⋠ L & P
    @test L & P ⋠ K & Q

    @test C ≼ A & B
    @test D ≼ A & B
    @test C ≼ A & C
    @test C ≼ B & C
    @test D ≼ A & C
    @test D ≼ B & C

end


@testset "interface intersections `remove_superinterfaces`" begin

    @test issetequal(
        remove_superinterfaces((A(), K & P)),
        (A(), K & P)
    )
    @test issetequal(
        remove_superinterfaces((A(), K & P, X())),
        (A(), K & P, X())
    )
    @test issetequal(
        remove_superinterfaces((A & K, P & X)),
        (A & K, P & X)
    )

    @test remove_superinterfaces((K(), K & P)) == (K & P, )
    @test remove_superinterfaces((K & P, K())) == (K & P, )
    @test remove_superinterfaces((P(), K & P)) == (K & P, )
    @test remove_superinterfaces((K & P, P())) == (K & P, )
    @test remove_superinterfaces((K(), K & P & X)) == (K & P & X, )
    @test remove_superinterfaces((K & P & X, K())) == (K & P & X, )

    @test issetequal(
        remove_superinterfaces((A(), K & P, K & P & X)),
        (A(), K & P & X)
    )
    @test issetequal(
        remove_superinterfaces((A(), K & P, K & Q)),
        (A(), K & Q)
    )
    @test issetequal(
        remove_superinterfaces((A(), K & P, L & P)),
        (A(), L & P)
    )
    @test issetequal(
        remove_superinterfaces((A(), K & P, L & Q)),
        (A(), L & Q)
    )
    @test issetequal(
        remove_superinterfaces((A(), K & P, L & Q & Y)),
        (A(), L & Q & Y)
    )
    @test remove_superinterfaces((K & P, L & Q & Y)) == (L & Q & Y, )

end


@testset "interface intersections `most_specific`" begin

    @test most_specific((A & B, C())) == C()
    @test most_specific((A & B, D())) == D()

    @test most_specific((K(), P(), K & P)) == K & P
    @test most_specific((K(), P(), K & P, K & P & X)) == K & P & X

    @test most_specific((K & P, K & Q)) == K & Q
    @test most_specific((K(), K & P, K & Q)) == K & Q
    @test most_specific((K(), P(), K & P, K & Q)) == K & Q
    @test most_specific((K(), P(), K & P, K & Q, K & Q & X)) == K & Q & X

    @test most_specific((K & P, L & P)) == L & P
    @test most_specific((K(), K & P, L & P)) == L & P
    @test most_specific((K(), P(), K & P, L & P)) == L & P
    @test most_specific((K(), P(), K & P, L & P, L & P & X)) == L & P & X

    @test most_specific((K & P, L & Q)) == L & Q
    @test most_specific((K(), K & P, L & Q)) == L & Q
    @test most_specific((K(), P(), K & P, L & Q)) == L & Q
    @test most_specific((K(), P(), K & P, L & Q & X)) == L & Q & X

    @test most_specific((A(), K(), P(), K & P, K & P & X)) == SingleArgumentAmbiguity()
    @test most_specific((C(), K & P)) == SingleArgumentAmbiguity()
    @test most_specific((K & Q, L & P)) == SingleArgumentAmbiguity()

end


end
