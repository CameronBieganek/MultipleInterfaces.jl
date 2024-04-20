

module DispatchTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: tail, in_tuple, delete, is_minimum, find_minimum, NoUniqueMinimum

@testset "dispatch" begin

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

    @test tail((A(), B(), C())) == (B(), C())
    @test tail((D(), )) === ()

    @test in_tuple(C(), (A(), B(), C()))
    @test !in_tuple(C(), (A(), B()))
    @test in_tuple(C(), (C(), ))
    @test !in_tuple(D(), ())

    @inferred in_tuple(C(), (A(), B(), C()))
    @inferred in_tuple(C(), (A(), B()))

    @test delete((A(), B(), C()), B()) == (A(), C())
    @test delete((A(), B(), C()), D()) == (A(), B(), C())

    @inferred delete((A(), B(), C()), B())
    @inferred delete((A(), B(), C()), D())

    @test is_minimum(E(), (B(), A()))
    @test !is_minimum(E(), (B(), A(), F()))

    @inferred is_minimum(E(), (B(), A()))
    @inferred is_minimum(E(), (B(), A(), F()))

    @test is_minimum(C(), (A(), ))
    @test !is_minimum(A(), (C(), ))

    @inferred is_minimum(C(), (A(), ))
    @inferred is_minimum(A(), (C(), ))

    @test find_minimum((B(), A(), E())) == E()
    @test find_minimum((B(), A(), E(), F())) == F()
    @test find_minimum((B(), F(), A(), E())) == F()
    @test find_minimum((A(), C(), B())) == C()
    @test find_minimum((C(), B(), D())) == NoUniqueMinimum()
    @test find_minimum((A(), H())) == NoUniqueMinimum()
    @test find_minimum((A(), C(), H())) == NoUniqueMinimum()

    @inferred find_minimum((B(), A(), E()))
    @inferred find_minimum((B(), A(), E(), F()))
    @inferred find_minimum((B(), F(), A(), E()))
    @inferred find_minimum((A(), C(), B()))
    @inferred find_minimum((C(), B(), D()))
    @inferred find_minimum((A(), G()))
    @inferred find_minimum((A(), C(), G()))
    @inferred find_minimum((A(), H()))
    @inferred find_minimum((A(), C(), H()))

end

end
