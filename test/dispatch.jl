

module AdhocMacroTests

using ExtendableInterfaces
using ExtendableInterfaces: signatures, interface_dispatches, InterfaceArg
using Test


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


@testset "@idispatch" begin

    @idispatch foo(a::Int, b: A, c::String, d: B) = 42

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    idispatches = interface_dispatches(foo, Int, InterfaceArg, String, InterfaceArg)
    @test issetequal(idispatches[1], (A(), ))
    @test issetequal(idispatches[2], (B(), ))


    @idispatch foo(a::Int, b: A, c::String, d: C) = 42

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    idispatches = interface_dispatches(foo, Int, InterfaceArg, String, InterfaceArg)
    @test issetequal(idispatches[1], (A(), ))
    @test issetequal(idispatches[2], (B(), C()))


    @idispatch foo(a::Int, b: F, c::String, d: H) = 42

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    idispatches = interface_dispatches(foo, Int, InterfaceArg, String, InterfaceArg)
    @test issetequal(idispatches[1], (A(), F()))
    @test issetequal(idispatches[2], (B(), C(), H()))


    @idispatch foo(a::Int, b: B, c::Int, d: D) = 42

    @test length(methods(foo)) == 2
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg)
    ])
    idispatches1 = interface_dispatches(foo, Int, InterfaceArg, String, InterfaceArg)
    @test issetequal(idispatches1[1], (A(), F()))
    @test issetequal(idispatches1[2], (B(), C(), H()))
    idispatches2 = interface_dispatches(foo, Int, InterfaceArg, Int, InterfaceArg)
    @test issetequal(idispatches2[1], (B(), ))
    @test issetequal(idispatches2[2], (D(), ))


    @idispatch foo(a::Int, b: C, c::Int, d: F) = 42

    @test length(methods(foo)) == 2
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg)
    ])
    idispatches1 = interface_dispatches(foo, Int, InterfaceArg, String, InterfaceArg)
    @test issetequal(idispatches1[1], (A(), F()))
    @test issetequal(idispatches1[2], (B(), C(), H()))
    idispatches2 = interface_dispatches(foo, Int, InterfaceArg, Int, InterfaceArg)
    @test issetequal(idispatches2[1], (B(), C()))
    @test issetequal(idispatches2[2], (D(), F()))


    @idispatch foo(a::Int, b: D, c::Int) = 42

    @test length(methods(foo)) == 3
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg),
        (Int, InterfaceArg, Int)
    ])
    idispatches1 = interface_dispatches(foo, Int, InterfaceArg, String, InterfaceArg)
    @test issetequal(idispatches1[1], (A(), F()))
    @test issetequal(idispatches1[2], (B(), C(), H()))
    idispatches2 = interface_dispatches(foo, Int, InterfaceArg, Int, InterfaceArg)
    @test issetequal(idispatches2[1], (B(), C()))
    @test issetequal(idispatches2[2], (D(), F()))
    idispatches3 = interface_dispatches(foo, Int, InterfaceArg, Int)
    @test issetequal(idispatches3[1], (D(), ))

end

end


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
    @idispatch foo(x: B) = 1
    @idispatch foo(x: C) = 2
    @idispatch foo(x: E) = 3
    @idispatch foo(x: F) = 4

    struct Cat end
    @type Cat implements B
    @type Cat implements E

    @test dispatch(foo, Cat()) == E()
    @test foo(Cat()) == 3

    struct Dog end
    @type Dog implements C, D

    @test dispatch(foo, Dog()) == C()
    @test foo(Dog()) == 2


    # ---- bar ----
    @idispatch bar(x: A) = 1
    @idispatch bar(x: C) = 2
    @idispatch bar(x: D) = 3
    @idispatch bar(x: E) = 4

    struct Bear end
    @type Bear implements C
    @type Bear implements D, E

    @test dispatch(bar, Bear()) == E()
    @test bar(Bear()) == 4

    struct Fish end
    @type Fish implements C, D

    @test dispatch(bar, Fish()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError bar(Fish())


    # ---- asdf ----
    @idispatch asdf(x: B) = 1
    @idispatch asdf(x: D) = 2
    @idispatch asdf(x: H) = 3

    struct Squid end
    @type Squid implements B
    @type Squid implements D

    @test dispatch(asdf, Squid()) == D()
    @test asdf(Squid()) == 2

    struct Crow end
    @type Crow implements B, H

    @test dispatch(asdf, Crow()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError asdf(Crow())

    struct Raven end
    @type Raven implements B, E

    @test dispatch(asdf, Raven()) == D()
    @test asdf(Raven()) == 2

    struct Goat end
    @type Goat implements H

    @test dispatch(asdf, Goat()) == H()
    @test asdf(Goat()) == 3


    # ---- qwer ----
    @idispatch qwer(x: A) = 1
    @idispatch qwer(x: B) = 2
    @idispatch qwer(x: C) = 3
    @idispatch qwer(x: D) = 4

    struct Lizard end
    @type Lizard implements A, B, C

    @test dispatch(qwer, Lizard()) == C()
    @test qwer(Lizard()) == 3

    struct Toad end
    @type Toad implements B
    @type Toad implements C
    @type Toad implements D

    @test dispatch(qwer, Toad()) == SpecificityAmbiguity()
    @test_throws InterfaceDispatchError qwer(Toad())

    struct Rabbit end
    @type Rabbit implements A

    @test dispatch(qwer, Rabbit()) == A()
    @test qwer(Rabbit()) == 1

    struct Eagle end
    @type Eagle implements B

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

    @idispatch baz(x: J) = 1

    struct Turtle end
    @type Turtle implements L

    @test dispatch(baz, Turtle()) == J()
    @test baz(Turtle()) == 1

    @idispatch aaa(x: J) = 1
    @idispatch aaa(x: K) = 2

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

    @idispatch bbb(x: M) = 1
    @idispatch bbb(x: O) = 2
    @idispatch bbb(x: P) = 3
    @idispatch bbb(x: R) = 4

    struct Frog end
    @type Frog implements N
    @type Frog implements Q

    @test dispatch(bbb, Frog()) == P()
    @test bbb(Frog()) == 3

end

end
