

####################################################################################################

module IDispatchMacroTests

using MultipleInterfaces
using MultipleInterfaces: signatures, interface_signatures, InterfaceArg
using Test


function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end
@interface D extends B begin d end
@interface E extends C, D begin e end
@interface F extends E begin f end
@interface G extends F begin g end

# Isolated node in interface DAG.
@interface H begin h end

@idispatch foo(a::Int, b: A, c::String, d: B) = 42

@testset "first @idispatch declaration" begin

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    @test interface_signatures(var"-idispatch-foo(Int,_,String,_)-") == ((A(), B()), )

end


@idispatch foo(a::Int, b: A, c::String, d: C) = 42

@testset "second @idispatch declaration" begin

    @test length(methods(foo)) == 1
    @test signatures(foo) == [
        (Int, InterfaceArg, String, InterfaceArg)
    ]
    @test issetequal(
        interface_signatures(var"-idispatch-foo(Int,_,String,_)-"),
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
    @test issetequal(
        interface_signatures(var"-idispatch-foo(Int,_,String,_)-"),
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
    @test interface_signatures(var"-idispatch-foo(Int,_,Int,_)-") == ((B(), D()), )

end


@idispatch foo(a::Int, b: C, c::Int, d: F) = 42

@testset "fifth @idispatch declaration" begin

    @test length(methods(foo)) == 2
    @test issetequal(signatures(foo), [
        (Int, InterfaceArg, String, InterfaceArg),
        (Int, InterfaceArg, Int, InterfaceArg)
    ])
    @test issetequal(
        interface_signatures(var"-idispatch-foo(Int,_,Int,_)-"),
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
    @test interface_signatures(var"-idispatch-foo(Int,_,Int)-") == ((D(), ), )

    # Make sure the first two interface signatures haven't been accidentally modified.
    @test issetequal(
        interface_signatures(var"-idispatch-foo(Int,_,String,_)-"),
        (
            (A(), B()),
            (A(), C()),
            (F(), H())
        )
    )
    @test issetequal(
        interface_signatures(var"-idispatch-foo(Int,_,Int,_)-"),
        (
            (B(), D()),
            (C(), F())
        )
    )

end

end



####################################################################################################

module SingleDispatchTests

using Test
using MultipleInterfaces
using MultipleInterfaces: dispatch, most_specific, SingleArgumentAmbiguity


function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end
@interface D extends B begin d end
@interface E extends C, D begin e end
@interface F extends E begin f end
@interface G extends F begin g end

# Isolated node in interface DAG.
@interface H begin h end


@testset "most_specific" begin
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
    @test_throws SingleArgumentAmbiguityError bar(Fish())

    # ---- asdf ----
    @test asdf(Squid()) == 2
    @test asdf(Raven()) == 2
    @test asdf(Goat()) == 3
    @test_throws SingleArgumentAmbiguityError asdf(Crow())

    # ---- qwer ----
    @test qwer(Lizard()) == 3
    @test qwer(Rabbit()) == 1
    @test qwer(Eagle()) == 2
    @test_throws SingleArgumentAmbiguityError qwer(Toad())

end


function j end
function k end
function l end

@interface J begin j end
@interface K begin k end
@interface L extends J, K begin l end

@idispatch baz(x: J) = 1

struct Turtle end
@type Turtle implements L

@idispatch aaa(x: J) = 1
@idispatch aaa(x: K) = 2

function m end
function n end
function o end
function p end
function q end
function r end
function s end

@interface M begin m end
@interface N extends M begin n end
@interface O begin o end
@interface P extends N, O begin p end
@interface Q extends P begin q end
@interface R begin r end
@interface S extends R begin s end

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
    @test_throws SingleArgumentAmbiguityError aaa(Turtle())

end

end



####################################################################################################

module MultipleDispatchTests

using Test
using MultipleInterfaces

function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

# A -> B -> C -> D
@interface A begin a end
@interface B extends A begin b end
@interface C extends B begin c end
@interface D extends C begin d end

# E -> F -> G -> H
@interface E begin e end
@interface F extends E begin f end
@interface G extends F begin g end
@interface H extends G begin h end

@idispatch foo(x::Int, b: B, f: F) = 1
@idispatch foo(x::Int, d: D, h: H) = 2
@idispatch foo(x::String, b: B, f: F) = 3
@idispatch foo(x::String, d: D, h: H) = 4

struct Ant end
struct Cat end
struct Dog end
struct Elephant end
struct Gerbal end
struct Hamster end

@type Ant implements A
@type Cat implements C
@type Dog implements D
@type Elephant implements E
@type Gerbal implements G
@type Hamster implements H

@testset "multiple-argument dispatch: foo" begin
    @test foo(1, Cat(), Gerbal()) == 1
    @test foo(1, Cat(), Hamster()) == 1
    @test foo(1, Dog(), Gerbal()) == 1
    @test foo(1, Dog(), Hamster()) == 2
    @test foo("a", Cat(), Gerbal()) == 3
    @test foo("a", Cat(), Hamster()) == 3
    @test foo("a", Dog(), Gerbal()) == 3
    @test foo("a", Dog(), Hamster()) == 4

    @test_throws NoMatchingIDispatchMethodError foo(1, Cat(), Cat())
    @test_throws NoMatchingIDispatchMethodError foo(1, Cat(), Dog())
    @test_throws NoMatchingIDispatchMethodError foo(1, Dog(), Cat())
    @test_throws NoMatchingIDispatchMethodError foo(1, Dog(), Dog())

    @test_throws NoMatchingIDispatchMethodError foo(1, Gerbal(), Cat())
    @test_throws NoMatchingIDispatchMethodError foo(1, Gerbal(), Dog())
    @test_throws NoMatchingIDispatchMethodError foo(1, Hamster(), Cat())
    @test_throws NoMatchingIDispatchMethodError foo(1, Hamster(), Dog())

    @test_throws NoMatchingIDispatchMethodError foo(1, Gerbal(), Gerbal())
    @test_throws NoMatchingIDispatchMethodError foo(1, Gerbal(), Hamster())
    @test_throws NoMatchingIDispatchMethodError foo(1, Hamster(), Gerbal())
    @test_throws NoMatchingIDispatchMethodError foo(1, Hamster(), Hamster())

    @test_throws NoMatchingIDispatchMethodError foo(1, Ant(), Elephant())
    @test_throws NoMatchingIDispatchMethodError foo(1, Ant(), Gerbal())
    @test_throws NoMatchingIDispatchMethodError foo(1, Ant(), Hamster())
    @test_throws NoMatchingIDispatchMethodError foo(1, Cat(), Elephant())
    @test_throws NoMatchingIDispatchMethodError foo(1, Dog(), Elephant())
end

end



####################################################################################################

module MultipleDispatchSingleArgumentAmbiguityTests

using Test
using MultipleInterfaces

function a end
function b end
function c end

function m end
function n end

function p end
function q end
function r end

@interface A begin a end
@interface B extends A begin
    b
end
@interface C extends A begin
    c
end

@interface M begin m end
@interface N extends M begin
    n
end

@interface P begin p end
@interface Q extends P begin
    q
end
@interface R extends P begin
    r
end

@idispatch foo(x::Int, a: A, m: M) = 1
@idispatch foo(x::Int, b: B, m: M) = 2
@idispatch foo(x::Int, c: C, m: M) = 3

@idispatch bar(x::Int, a: A, p: P) = 1
@idispatch bar(x::Int, b: B, q: Q) = 2
@idispatch bar(x::Int, c: C, r: R) = 3

struct Cat end
struct Dog end
struct Horse end

@type Cat implements B, C
@type Dog implements N
@type Horse implements Q, R

@testset "multiple-dispatch single-argument ambiguity" begin
    @test_throws SingleArgumentAmbiguityError foo(1, Cat(), Dog())
    @test_throws SingleArgumentAmbiguityError bar(1, Cat(), Horse())
end

end



####################################################################################################

module MultipleDispatchMultipleArgumentAmbiguityTests

using Test
using MultipleInterfaces

function a end
function b end

function p end
function q end

# A -> B
@interface A begin a end
@interface B extends A begin
    b
end

# P -> Q
@interface P begin p end
@interface Q extends P begin
    q
end

@idispatch foo(x::Int, a: A, p: P) = 1
@idispatch foo(x::Int, b: B, p: P) = 2
@idispatch foo(x::Int, a: A, q: Q) = 3

struct Cat end
struct Dog end

@type Cat implements B
@type Dog implements Q

@testset "multiple-dispatch multiple-argument ambiguity" begin
    @test_throws MultipleArgumentAmbiguityError foo(1, Cat(), Dog())
end

end



####################################################################################################

module ComplicatedMultipleDispatchTests

using Test
using MultipleInterfaces

function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end
@interface D extends B begin d end
@interface E extends C, D begin e end
@interface F extends E begin f end
@interface G extends F begin g end

# Isolated node in interface DAG.
@interface H begin h end

function m end
function n end
function o end
function p end
function q end
function r end
function s end
function t end

@interface M begin m end
@interface N begin n end
@interface O begin o end
@interface P extends M, N begin p end
@interface Q extends N, O begin q end
@interface R extends P begin r end
@interface S extends P, Q begin s end
@interface T extends Q begin t end

struct Cat end
struct Dog end
struct Fox end
struct Horse end
struct Newt end
struct Parrot end
struct Salamander end
struct Tiger end

struct Chameleon end

@type Cat implements C
@type Dog implements D
@type Fox implements F
@type Horse implements H
@type Newt implements N
@type Parrot implements P
@type Salamander implements S
@type Tiger implements T

@type Chameleon implements F, S

@idispatch foo(c: C, x::String, n: N) = 1
@idispatch foo(c: E, x::String, n: N) = 2
@idispatch foo(c: F, x::String, p: P) = 3
@idispatch foo(c: G, x::String, n: N) = 4

@testset "complicated DAG: foo" begin
    @test_throws MethodError foo(Cat(), 42, Parrot())
    @test_throws MethodError foo(Dog(), 3.14, Horse())
    @test_throws MethodError foo(Fox(), 42, Parrot())

    @test (
        foo(Cat(), "a", Newt()) ==
        foo(Cat(), "a", Parrot()) ==
        foo(Cat(), "a", Salamander()) ==
        foo(Cat(), "a", Tiger()) ==
        foo(Cat(), "a", Chameleon()) ==
        1
    )

    @test (
        foo(Fox(), "a", Tiger()) ==
        foo(Fox(), "a", Newt()) ==
        foo(Chameleon(), "a", Tiger()) ==
        foo(Chameleon(), "a", Newt()) ==
        2
    )

    @test_throws NoMatchingIDispatchMethodError foo(Dog(), "a", Newt())
    @test_throws NoMatchingIDispatchMethodError foo(Dog(), "a", Parrot())
    @test_throws NoMatchingIDispatchMethodError foo(Dog(), "a", Salamander())
    @test_throws NoMatchingIDispatchMethodError foo(Dog(), "a", Tiger())

    @test (
        foo(Fox(), "a", Parrot()) ==
        foo(Fox(), "a", Salamander()) ==
        foo(Chameleon(), "a", Parrot()) ==
        foo(Chameleon(), "a", Salamander()) ==
        foo(Chameleon(), "a", Chameleon()) ==
        3
    )
end

@idispatch bar(h: H) = 1

@testset "complicated DAG: bar" begin
    @test bar(Horse()) == 1
    @test_throws NoMatchingIDispatchMethodError bar(Cat())
    @test_throws NoMatchingIDispatchMethodError bar(Fox())
    @test_throws NoMatchingIDispatchMethodError bar(Salamander())
    @test_throws NoMatchingIDispatchMethodError bar(Tiger())
    @test_throws NoMatchingIDispatchMethodError bar(Chameleon())
end

@idispatch asdf(x::Int, n: N, e: E) = 1
@idispatch asdf(x::Int, p: P, e: E) = 2
@idispatch asdf(x::Int, q: Q, e: E) = 3

struct Rooster end
@type Rooster implements P, Q

@testset "complicated DAG: single-argument ambiguity" begin
    @test_throws MethodError asdf("hello", Newt(), Fox())
    @test asdf(1, Newt(), Fox()) == 1
    @test asdf(1, Parrot(), Fox()) == 2
    @test_throws SingleArgumentAmbiguityError asdf(1, Rooster(), Fox())
end

@idispatch qwer(c: C, p: P, x::Char) = 1
@idispatch qwer(f: F, p: P, x::Char) = 2
@idispatch qwer(c: C, s: S, x::Char) = 3

@testset "complicated DAG: multiple-argument ambiguity" begin
    @test qwer(Cat(), Parrot(), 'a') == 1
    @test qwer(Fox(), Parrot(), 'a') == 2
    @test qwer(Cat(), Salamander(), 'a') == 3
    @test_throws MultipleArgumentAmbiguityError qwer(Fox(), Salamander(), 'a')
end

end



####################################################################################################

module DispatchWithModulePrefixedInterfaces

using Test
using MultipleInterfaces


module Foo
    using MultipleInterfaces
    function a end
    @interface A begin a end
end

module Bar
    using MultipleInterfaces

    module Qux
        function b end
    end

    @interface B begin Qux.b end
end

function c end

@interface C extends Bar.B begin c end

@testset "`@interface` with module prefixes" begin
    @test C ≼ Bar.B

    methods = required_methods(Foo.A)
    @test issetequal(methods, [Foo.a])
    @test methods isa AbstractVector

    methods = required_methods(Bar.B)
    @test issetequal(methods, [Bar.Qux.b])
    @test methods isa AbstractVector

    methods = required_methods(C)
    @test issetequal(methods, [c])
    @test methods isa AbstractVector

    @test superinterfaces(Foo.A) == ()
    @test superinterfaces(Bar.B) == ()
    @test superinterfaces(C) == (Bar.B, )
end


struct Ant end
struct Bear end
struct Cat end
struct Mouse end

@type Ant implements Foo.A
@type Bear implements Bar.B
@type Cat implements C
@type Mouse implements Foo.A, Bar.B

@testset "`@type` with module prefixes" begin
    @test implements(Ant) == (Foo.A, )
    @test implements(Bear) == (Bar.B, )
    @test issetequal(implements(Cat), (Bar.B, C))
    @test issetequal(implements(Mouse), (Foo.A, Bar.B))
end


@idispatch asdf(a: Foo.A, b: Bar.B) = 1
@idispatch asdf(x: Foo.A & Bar.B) = 2
@idispatch asdf(a: Foo.A, c: C) = 3

@testset "`@idispatch` with module prefixes" begin
    @test asdf(Ant(), Bear()) == 1
    @test asdf(Mouse()) == 2
    @test asdf(Ant(), Cat()) == 3

    @test_throws MethodError asdf(1, 2, 3)
    @test_throws NoMatchingIDispatchMethodError asdf(42)
    @test_throws NoMatchingIDispatchMethodError asdf(Bear(), Ant())
    @test_throws NoMatchingIDispatchMethodError asdf(Ant())
end

end



####################################################################################################

module TestWhenPackageNameNotInScope

using Test
using MultipleInterfaces: @interface, @type, @idispatch, NoMatchingIDispatchMethodError

function a end
function b end

@interface A begin a end
@interface B begin b end

struct Ant end
struct Bear end

@type Ant implements A
@type Bear implements B

@idispatch foo(a: A) = 1
@idispatch foo(b: B) = 2

@testset "package name not in scope" begin
    @test foo(Ant()) == 1
    @test foo(Bear()) == 2

    @test_throws MethodError foo(1, 2)
    @test_throws NoMatchingIDispatchMethodError foo(1)
end

end



####################################################################################################

module DispatchOnParametricTypes

using Test
using MultipleInterfaces

function a end
function b end
function c end

@interface A begin a end
@interface B begin b end
@interface C begin c end

struct Ant{T} end
struct Bear{T <: Real} end
struct Cat{T <: Number} end

@type Ant implements A
@type Bear{<:Integer} implements B
@type Cat{Float64} implements C

@idispatch foo(a: A) = 1
@idispatch foo(b: B) = 2
@idispatch foo(c: C) = 3

@testset "dispatch on parametric types" begin
    @test foo(Ant{Int}()) == 1
    @test foo(Ant{String}()) == 1
    @test foo(Ant{AbstractFloat}()) == 1

    @test foo(Bear{Int32}()) == 2
    @test foo(Bear{Int64}()) == 2

    @test foo(Cat{Float64}()) == 3

    @test_throws NoMatchingIDispatchMethodError foo(Bear{Float32}())
    @test_throws NoMatchingIDispatchMethodError foo(Bear{Float64}())
    @test_throws NoMatchingIDispatchMethodError foo(Cat{Float32}())
    @test_throws NoMatchingIDispatchMethodError foo(Cat{Int64}())
end

end
