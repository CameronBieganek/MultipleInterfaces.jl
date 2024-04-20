

module DispatchTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: tail, in_tuple, delete, is_most_specific
using ExtendableInterfaces: most_specific, SpecificityAmbiguity

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

    @test is_most_specific(E(), (B(), A()))
    @test !is_most_specific(E(), (B(), A(), F()))

    @inferred is_most_specific(E(), (B(), A()))
    @inferred is_most_specific(E(), (B(), A(), F()))

    @test is_most_specific(C(), (A(), ))
    @test !is_most_specific(A(), (C(), ))

    @inferred is_most_specific(C(), (A(), ))
    @inferred is_most_specific(A(), (C(), ))

    @test most_specific((B(), A(), E())) == E()
    @test most_specific((B(), A(), E(), F())) == F()
    @test most_specific((B(), F(), A(), E())) == F()
    @test most_specific((A(), C(), B())) == C()
    @test most_specific((C(), B(), D())) == SpecificityAmbiguity()
    @test most_specific((A(), H())) == SpecificityAmbiguity()
    @test most_specific((A(), C(), H())) == SpecificityAmbiguity()

    @inferred most_specific((B(), A(), E()))
    @inferred most_specific((B(), A(), E(), F()))
    @inferred most_specific((B(), F(), A(), E()))
    @inferred most_specific((A(), C(), B()))
    @inferred most_specific((C(), B(), D()))
    @inferred most_specific((A(), G()))
    @inferred most_specific((A(), C(), G()))
    @inferred most_specific((A(), H()))
    @inferred most_specific((A(), C(), H()))

end

end
