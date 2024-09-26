

module IDispatchMacroTests

using ExtendableInterfaces
using ExtendableInterfaces: signatures, interface_args_dispatches
using ExtendableInterfaces: interface_signatures, InterfaceArg
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


@idispatch foo(a::Int, b: A, c::String, d: B) = 42

@testset "first @idispatch declaration" begin

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    idispatches = interface_args_dispatches(var"idispatch#foo(Int,_,String,_)")
    @test issetequal(idispatches[1], (A(), ))
    @test issetequal(idispatches[2], (B(), ))
    @test interface_signatures(var"idispatch#foo(Int,_,String,_)") == ((A(), B()), )

end


@idispatch foo(a::Int, b: A, c::String, d: C) = 42

@testset "second @idispatch declaration" begin

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    idispatches = interface_args_dispatches(var"idispatch#foo(Int,_,String,_)")
    @test issetequal(idispatches[1], (A(), ))
    @test issetequal(idispatches[2], (B(), C()))
    @test issetequal(
        interface_signatures(var"idispatch#foo(Int,_,String,_)"),
        (
            (A(), B()),
            (A(), C())
        )
    )

end


@idispatch foo(a::Int, b: F, c::String, d: H) = 42

@testset "third @idispatch declaration" begin

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    idispatches = interface_args_dispatches(var"idispatch#foo(Int,_,String,_)")
    @test issetequal(idispatches[1], (A(), F()))
    @test issetequal(idispatches[2], (B(), C(), H()))
    @test issetequal(
        interface_signatures(var"idispatch#foo(Int,_,String,_)"),
        (
            (A(), B()),
            (A(), C()),
            (F(), H())
        )
    )

end


@idispatch foo(a::Int, b: B, c::Int, d: D) = 42

@testset "fourth @idispatch declaration" begin

    @test length(methods(foo)) == 2
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg)
    ])
    idispatches1 = interface_args_dispatches(var"idispatch#foo(Int,_,String,_)")
    @test issetequal(idispatches1[1], (A(), F()))
    @test issetequal(idispatches1[2], (B(), C(), H()))
    idispatches2 = interface_args_dispatches(var"idispatch#foo(Int,_,Int,_)")
    @test issetequal(idispatches2[1], (B(), ))
    @test issetequal(idispatches2[2], (D(), ))
    @test interface_signatures(var"idispatch#foo(Int,_,Int,_)") == ((B(), D()), )

end


@idispatch foo(a::Int, b: C, c::Int, d: F) = 42

@testset "fifth @idispatch declaration" begin

    @test length(methods(foo)) == 2
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg)
    ])
    idispatches1 = interface_args_dispatches(var"idispatch#foo(Int,_,String,_)")
    @test issetequal(idispatches1[1], (A(), F()))
    @test issetequal(idispatches1[2], (B(), C(), H()))
    idispatches2 = interface_args_dispatches(var"idispatch#foo(Int,_,Int,_)")
    @test issetequal(idispatches2[1], (B(), C()))
    @test issetequal(idispatches2[2], (D(), F()))
    @test issetequal(
        interface_signatures(var"idispatch#foo(Int,_,Int,_)"),
        (
            (B(), D()),
            (C(), F())
        )
    )

end


@idispatch foo(a::Int, b: D, c::Int) = 42

@testset "sixth @idispatch declaration" begin
    @test length(methods(foo)) == 3
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg),
        (Int, InterfaceArg, Int)
    ])
    idispatches1 = interface_args_dispatches(var"idispatch#foo(Int,_,String,_)")
    @test issetequal(idispatches1[1], (A(), F()))
    @test issetequal(idispatches1[2], (B(), C(), H()))
    idispatches2 = interface_args_dispatches(var"idispatch#foo(Int,_,Int,_)")
    @test issetequal(idispatches2[1], (B(), C()))
    @test issetequal(idispatches2[2], (D(), F()))
    idispatches3 = interface_args_dispatches(var"idispatch#foo(Int,_,Int)")
    @test issetequal(idispatches3[1], (D(), ))
    @test interface_signatures(var"idispatch#foo(Int,_,Int)") == ((D(), ), )


    # Make sure the first two interface signatures haven't been accidentally modified.
    @test issetequal(
        interface_signatures(var"idispatch#foo(Int,_,String,_)"),
        (
            (A(), B()),
            (A(), C()),
            (F(), H())
        )
    )
    @test issetequal(
        interface_signatures(var"idispatch#foo(Int,_,Int,_)"),
        (
            (B(), D()),
            (C(), F())
        )
    )

end

end



module SingleDispatchTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: tail, in_t, delete, is_subinterface_all
using ExtendableInterfaces: most_specific, SingleArgumentAmbiguity, dispatch


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


@testset "dispatch helpers" begin

    @test tail((A(), B(), C())) == (B(), C())
    @test tail((D(), )) === ()

    @test in_t(C(), (A(), B(), C()))
    @test !in_t(C(), (A(), B()))
    @test in_t(C(), (C(), ))
    @test !in_t(D(), ())

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
    @test most_specific((C(), B(), D())) == SingleArgumentAmbiguity()
    @test most_specific((A(), H())) == SingleArgumentAmbiguity()
    @test most_specific((A(), C(), H())) == SingleArgumentAmbiguity()
end


# ---- foo ----
@idispatch foo(x: B) = 1
@idispatch foo(x: C) = 2
@idispatch foo(x: E) = 3
@idispatch foo(x: F) = 4

struct Cat end
@type Cat implements B
@type Cat implements E

struct Dog end
@type Dog implements C, D


# ---- bar ----
@idispatch bar(x: A) = 1
@idispatch bar(x: C) = 2
@idispatch bar(x: D) = 3
@idispatch bar(x: E) = 4

struct Bear end
@type Bear implements C
@type Bear implements D, E

struct Fish end
@type Fish implements C, D


# ---- asdf ----
@idispatch asdf(x: B) = 1
@idispatch asdf(x: D) = 2
@idispatch asdf(x: H) = 3

struct Squid end
@type Squid implements B
@type Squid implements D

struct Crow end
@type Crow implements B, H

struct Raven end
@type Raven implements B, E

struct Goat end
@type Goat implements H


# ---- qwer ----
@idispatch qwer(x: A) = 1
@idispatch qwer(x: B) = 2
@idispatch qwer(x: C) = 3
@idispatch qwer(x: D) = 4

struct Lizard end
@type Lizard implements A, B, C

struct Toad end
@type Toad implements B
@type Toad implements C
@type Toad implements D

struct Rabbit end
@type Rabbit implements A

struct Eagle end
@type Eagle implements B


@testset "single-argument dispatch" begin

    # ---- foo ----
    @test foo(Cat()) == 3
    @test foo(Dog()) == 2

    # ---- bar ----
    @test bar(Bear()) == 4
    @test_throws InterfaceDispatchError bar(Fish())

    # ---- asdf ----
    @test asdf(Squid()) == 2
    @test asdf(Raven()) == 2
    @test asdf(Goat()) == 3
    @test_throws InterfaceDispatchError asdf(Crow())

    # ---- qwer ----
    @test qwer(Lizard()) == 3
    @test qwer(Rabbit()) == 1
    @test qwer(Eagle()) == 2
    @test_throws InterfaceDispatchError qwer(Toad())

end


function j end
function k end

@interface J begin j end
@interface K begin k end
@interface L extends J, K

@idispatch baz(x: J) = 1

struct Turtle end
@type Turtle implements L

@idispatch aaa(x: J) = 1
@idispatch aaa(x: K) = 2

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


@testset "dispatch with transitive implements" begin

    # ---- Test transitive "implements" declarations. --------
    # If a type declares that it implements an interface, it must also implement
    # all the superinterfaces of that interface.

    @test baz(Turtle()) == 1
    @test bbb(Frog()) == 3
    @test_throws InterfaceDispatchError aaa(Turtle())

end

end



module MultipleDispatchTests

using Test
using ExtendableInterfaces

function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

@interface A begin a end
@interface B extends A begin b end
@interface C extends B begin c end
@interface D extends C begin d end
@interface E begin e end
@interface F extends E begin f end
@interface G extends F begin g end
@interface H extends G begin h end

@idispatch foo(::Int, b: B, f: F) = 1
@idispatch foo(::Int, d: D, h: H) = 2
@idispatch foo(::String, b: B, f: F) = 3
@idispatch foo(::String, d: D, h: H) = 4

struct Cat end
struct Dog end
struct Frog end
struct Lizard end

@type Cat implements C
@type Dog implements D
@type Frog implements G
@type Lizard implements H

@testset "multiple argument dispatch: foo" begin
    @test foo(1, Cat(), Frog()) == 1
    @test foo(1, Dog(), Lizard()) == 2
    @test foo("a", Cat(), Frog()) == 3
    @test foo("a", Dog(), Lizard()) == 4

    @test_broken foo(1, Cat(), Lizard()) == 1
    @test_broken foo(1, Dog(), Frog()) == 1
end

end
