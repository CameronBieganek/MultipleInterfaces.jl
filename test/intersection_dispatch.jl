

module IntersectionDispatchTests

using Test
using MultipleInterfaces


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

struct Ant end
struct Bear end
struct Cat end
struct Dog end
struct Koala end
struct Lizard end
struct Panda end
struct Quail end
struct Xerus end
struct Yak end

@type Ant implements A
@type Bear implements B
@type Cat implements C
@type Dog implements D
@type Koala implements K
@type Lizard implements L
@type Panda implements P
@type Quail implements Q
@type Xerus implements X
@type Yak implements Y

struct Barge end
struct Bicycle end
struct Blimp end
struct Boat end

struct Scooter end
struct Skateboard end

@type Barge implements K, P
@type Bicycle implements L, P
@type Blimp implements K, Q
@type Boat implements L, Q

@type Scooter implements K, P, X
@type Skateboard implements K, P, Y

@idispatch foo(z::Int, a: A, x: K & P) = 1
@idispatch foo(z::Int, c: C, x: K & P) = 2
@idispatch foo(z::Int, d: D, x: K & P) = 3
@idispatch foo(z::Int, a: A, x: L & P) = 4
@idispatch foo(z::Int, a: A, x: K & Q) = 5
@idispatch foo(z::Int, a: A, x: L & Q) = 6
@idispatch foo(z::Int, a: A, x: K & P & X) = 7
@idispatch foo(z::Int, a: A, x: K & P & Y) = 8


@testset "interface intersection dispatch `foo`" begin

    @test foo(42, Ant(), Barge())      == 1
    @test foo(42, Cat(), Barge())      == 2
    @test foo(42, Dog(), Barge())      == 3
    @test foo(42, Ant(), Bicycle())    == 4
    @test foo(42, Ant(), Blimp())      == 5
    @test foo(42, Ant(), Boat())       == 6
    @test foo(42, Ant(), Scooter())    == 7
    @test foo(42, Ant(), Skateboard()) == 8

    @test_throws MultipleArgumentAmbiguityError foo(42, Cat(), Bicycle())
    @test_throws MultipleArgumentAmbiguityError foo(42, Cat(), Blimp())
    @test_throws MultipleArgumentAmbiguityError foo(42, Cat(), Boat())
    @test_throws MultipleArgumentAmbiguityError foo(42, Cat(), Scooter())
    @test_throws MultipleArgumentAmbiguityError foo(42, Cat(), Skateboard())

    @test_throws NoMatchingIDispatchMethodError foo(42, Ant(), Ant())
    @test_throws NoMatchingIDispatchMethodError foo(42, Blimp(), Scooter())
    @test_throws NoMatchingIDispatchMethodError foo(42, Bicycle(), Cat())

    @test_throws MethodError foo(42, 42)
    @test_throws MethodError foo(42, "hello")
    @test_throws MethodError foo(42)
    @test_throws MethodError foo(42, Ant())
    @test_throws MethodError foo(Ant(), 42, Barge())

end


@idispatch bar(a: A, x: K & P) = 1


@testset "interface intersection dispatch `bar`" begin

    @test bar(Ant(), Barge())      == 1
    @test bar(Ant(), Bicycle())    == 1
    @test bar(Ant(), Blimp())      == 1
    @test bar(Ant(), Boat())       == 1
    @test bar(Ant(), Scooter())    == 1
    @test bar(Ant(), Skateboard()) == 1

    @test bar(Cat(), Barge())      == 1
    @test bar(Cat(), Bicycle())    == 1
    @test bar(Cat(), Blimp())      == 1
    @test bar(Cat(), Boat())       == 1
    @test bar(Cat(), Scooter())    == 1
    @test bar(Cat(), Skateboard()) == 1

    @test bar(Dog(), Barge())      == 1
    @test bar(Dog(), Bicycle())    == 1
    @test bar(Dog(), Blimp())      == 1
    @test bar(Dog(), Boat())       == 1
    @test bar(Dog(), Scooter())    == 1
    @test bar(Dog(), Skateboard()) == 1

    @test_throws NoMatchingIDispatchMethodError bar(Ant(), Ant())
    @test_throws NoMatchingIDispatchMethodError bar(Blimp(), Scooter())
    @test_throws NoMatchingIDispatchMethodError bar(Bicycle(), Cat())

    @test_throws MethodError bar()
    @test_throws MethodError bar(42)
    @test_throws MethodError bar(Ant())
    @test_throws MethodError bar(Ant(), Bear(), Cat())

end


@idispatch asdf(x: K & P) = 1
@idispatch asdf(x: L & P) = 2
@idispatch asdf(x: K & Q) = 3


@testset "interface intersection dispatch `asdf`" begin

    @test asdf(Barge())      == 1
    @test asdf(Scooter())    == 1
    @test asdf(Skateboard()) == 1
    @test asdf(Bicycle())    == 2
    @test asdf(Blimp())      == 3

    @test_throws SingleArgumentAmbiguityError asdf(Boat())

end


@idispatch qwer(x: L & P) = 1
@idispatch qwer(x: K & Q) = 2


@testset "interface intersection dispatch `qwer`" begin

    @test qwer(Bicycle()) == 1
    @test qwer(Blimp())   == 2
    @test_throws NoMatchingIDispatchMethodError qwer(Barge())
    @test_throws SingleArgumentAmbiguityError qwer(Boat())

end


struct Earth end
struct Fire end
struct Water end
struct Wind end

@type Earth implements C, K
@type Fire implements D, L
@type Water implements P, X
@type Wind implements Q, Y

@idispatch buzz(x: C & K, y: P & X) = 1
@idispatch buzz(x: D & L, y: Q & Y) = 2


@testset "interface intersection dispatch `buzz`" begin

    @test buzz(Earth(), Water()) == 1
    @test buzz(Earth(), Wind()) == 1
    @test buzz(Fire(), Water()) == 1
    @test buzz(Fire(), Wind()) == 2

    @test_throws NoMatchingIDispatchMethodError buzz(Earth(), Earth())
    @test_throws NoMatchingIDispatchMethodError buzz(Wind(), Fire())

end


@idispatch qux(x: D & L, y: P & X) = 1
@idispatch qux(x: C & K, y: Q & Y) = 2


@testset "interface intersection dispatch `qux`" begin

    @test_throws NoMatchingIDispatchMethodError qux(Earth(), Water())
    @test qux(Fire(), Water()) == 1
    @test qux(Earth(), Wind()) == 2
    @test_throws MultipleArgumentAmbiguityError qux(Fire(), Wind())

end


struct Plane end
@type Plane implements K, P, X

@idispatch f(x: K & P) = 1
@idispatch f(x: K & X) = 2


@testset "interface intersection dispatch `f`" begin
    @test_throws SingleArgumentAmbiguityError f(Plane())
end

end




module MoreIntersectionDispatchTests

using Test
using MultipleInterfaces

function a end
function b end
function c end
function d end

@interface A begin a end
@interface B begin b end
@interface C begin c end
@interface D extends C begin d end

struct Cat end
struct Dog end
struct Mouse end

@type Cat implements C
@type Dog implements D
@type Mouse implements A, B

@idispatch foo(x: A & B, y: C) = 1
@idispatch foo(x: B & A, y: D) = 2

@test foo(Mouse(), Cat()) == 1
@test foo(Mouse(), Dog()) == 2

end




module IMethodRedefinitionTests

using Test
using MultipleInterfaces


function a end
function b end
function c end

@interface A begin a end
@interface B begin b end
@interface C begin c end

struct Ant end
struct Mouse end

@type Ant implements A
@type Mouse implements B, C


@idispatch foo(x: A) = 1

@testset "`foo` method first definition" begin
    @test foo(Ant()) == 1
end

@idispatch foo(x: A) = 2

@testset "`foo` method second definition" begin
    @test foo(Ant()) == 2
end


@idispatch bar(x: A, y: B & C) = 1

@testset "`bar` method first definition" begin
    @test bar(Ant(), Mouse()) == 1
end

@idispatch bar(x: A, y: B & C) = 2

@testset "`bar` method second definition" begin
    @test bar(Ant(), Mouse()) == 2
end

@idispatch bar(x: A, y: C & B) = 3

@testset "`bar` method second definition" begin
    @test bar(Ant(), Mouse()) == 3
end

end
