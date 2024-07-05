

module DispatchTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: tail, in_tuple, delete, is_subinterface_all
using ExtendableInterfaces: most_specific, SpecificityAmbiguity, dispatch

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

    @test delete((A(), B(), C()), B()) == (A(), C())
    @test delete((A(), B(), C()), D()) == (A(), B(), C())

    @test is_subinterface_all(E(), (B(), A()))
    @test !is_subinterface_all(E(), (B(), A(), F()))

    @test is_subinterface_all(C(), (A(), ))
    @test !is_subinterface_all(A(), (C(), ))

    @test most_specific((B(), A(), E())) == E()
    @test most_specific((B(), A(), E(), F())) == F()
    @test most_specific((B(), F(), A(), E())) == F()
    @test most_specific((A(), C(), B())) == C()
    @test most_specific((C(), B(), D())) == SpecificityAmbiguity()
    @test most_specific((A(), H())) == SpecificityAmbiguity()
    @test most_specific((A(), C(), H())) == SpecificityAmbiguity()


    # ---- foo ----
    @declare foo(x: _)
    @adhoc foo(x: B) = 1
    @adhoc foo(x: C) = 2
    @adhoc foo(x: E) = 3
    @adhoc foo(x: F) = 4

    struct Cat end
    @implements Cat: B
    @implements Cat: E

    @test dispatch(foo, Cat()) == E()
    @test foo(Cat()) == 3

    struct Dog end
    @implements Dog: C
    @implements Dog: D

    @test dispatch(foo, Dog()) == C()
    @test foo(Dog()) == 2


    # ---- bar ----
    @declare bar(x: _)
    @adhoc bar(x: A) = 1
    @adhoc bar(x: C) = 2
    @adhoc bar(x: D) = 3
    @adhoc bar(x: E) = 4

    struct Bear end
    @implements Bear: C
    @implements Bear: D
    @implements Bear: E

    @test dispatch(bar, Bear()) == E()
    @test bar(Bear()) == 4

    struct Fish end
    @implements Fish: C
    @implements Fish: D

    @test dispatch(bar, Fish()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError bar(Fish())


    # ---- asdf ----
    @declare asdf(x: _)
    @adhoc asdf(x: B) = 1
    @adhoc asdf(x: D) = 2
    @adhoc asdf(x: H) = 3

    struct Squid end
    @implements Squid: B
    @implements Squid: D

    @test dispatch(asdf, Squid()) == D()
    @test asdf(Squid()) == 2

    struct Crow end
    @implements Crow: B
    @implements Crow: H

    @test dispatch(asdf, Crow()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError asdf(Crow())

    struct Raven end
    @implements Raven: B
    @implements Raven: E

    @test dispatch(asdf, Raven()) == D()
    @test asdf(Raven()) == 2

    struct Goat end
    @implements Goat: H

    @test dispatch(asdf, Goat()) == H()
    @test asdf(Goat()) == 3


    # ---- qwer ----
    @declare qwer(x: _)
    @adhoc qwer(x: A) = 1
    @adhoc qwer(x: B) = 2
    @adhoc qwer(x: C) = 3
    @adhoc qwer(x: D) = 4

    struct Lizard end
    @implements Lizard: A
    @implements Lizard: B
    @implements Lizard: C

    @test dispatch(qwer, Lizard()) == C()
    @test qwer(Lizard()) == 3

    struct Toad end
    @implements Toad: B
    @implements Toad: C
    @implements Toad: D

    @test dispatch(qwer, Toad()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError qwer(Toad())

    struct Rabbit end
    @implements Rabbit: A

    @test dispatch(qwer, Rabbit()) == A()
    @test qwer(Rabbit()) == 1

    struct Eagle end
    @implements Eagle: B

    @test dispatch(qwer, Eagle()) == B()
    @test qwer(Eagle()) == 2


    # ---- Test transitive "implements" declarations. --------
    # If a type declares that it implements an interface, it must also implement
    # all the superinterfaces of that interface.

    function j end
    function k end

    @interface J begin j end
    @interface K begin k end
    @interface L extends J, K

    @declare baz(x: _)
    @adhoc baz(x: J) = 1

    struct Turtle end
    @implements Turtle: L

    @test dispatch(baz, Turtle()) == J()
    @test baz(Turtle()) == 1

    @declare aaa(x: _)
    @adhoc aaa(x: J) = 1
    @adhoc aaa(x: K) = 2

    @test dispatch(aaa, Turtle()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError aaa(Turtle())

    function m end
    function o end
    function r end

    @interface M begin m end
    @interface N extends M
    @interface O begin o end
    @interface P extends N, O
    @interface Q extends P
    @interface R begin r end
    @interface S extends R

    @declare bbb(x: _)
    @adhoc bbb(x: M) = 1
    @adhoc bbb(x: O) = 2
    @adhoc bbb(x: P) = 3
    @adhoc bbb(x: R) = 4

    struct Frog end
    @implements Frog: N
    @implements Frog: Q

    @test dispatch(bbb, Frog()) == P()
    @test bbb(Frog()) == 3

end

end
