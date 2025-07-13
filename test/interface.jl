

module InterfaceMacroTests

using MultipleInterfaces
using Test


function a1 end
function a2 end

@interface A begin
    a1
    a2
end

function b1 end
function b2 end

@interface B begin
    b1
    b2
end

function c1 end

@interface C extends A, B begin
    c1
end

function d1 end

@interface D extends C begin
    d1
end


@testset "@interface" begin
    @test A() === A()
    @test superinterfaces(A) == ()

    methods = required_methods(A)
    @test issetequal(methods, [a1, a2])
    @test methods isa AbstractVector

    @test B() === B()
    @test superinterfaces(B) == ()

    methods = required_methods(B)
    @test issetequal(methods, [b1, b2])
    @test methods isa AbstractVector

    @test C() === C()
    @test issetequal(superinterfaces(C), (A, B))
    @test required_methods(C) == [c1]

    @test D() === D()
    @test superinterfaces(D) == (C, )
    @test required_methods(D) == [d1]

    methods = all_required_methods(A)
    @test issetequal(methods, [a1, a2])
    @test methods isa AbstractVector

    methods = all_required_methods(B)
    @test issetequal(methods, [b1, b2])
    @test methods isa AbstractVector

    methods = all_required_methods(C)
    @test issetequal(methods, [a1, a2, b1, b2, c1])
    @test methods isa AbstractVector

    methods = all_required_methods(D)
    @test issetequal(methods, [a1, a2, b1, b2, c1, d1])
    @test methods isa AbstractVector
end

end



module AncestorsTests

using Test
using MultipleInterfaces
using MultipleInterfaces: ancestors

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

@testset "ancestors" begin

    @test ancestors(H()) == (H(), )
    @test ancestors(A()) == (A(), )
    @test ancestors(B()) == (B(), )
    @test issetequal(
        ancestors(F()),
        (A(), B(), C(), D(), E(), F())
    )
    @test issetequal(
        ancestors(C()),
        (A(), B(), C())
    )
    @test issetequal(
        ancestors(D()),
        (B(), D())
    )

end

end



module TypeMacroTests

using Test
using MultipleInterfaces


function a end
function b end
function c end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end

struct Cat end
struct Dog end
struct Fox end
struct Alligator end
struct Crocodile end

@type Cat implements A
@type Dog implements B
@type Fox implements A, B
@type Alligator implements A, B, C
@type Crocodile implements C


@testset "@type" begin
    @test implements(Cat) == (A, )
    @test implements(Dog) == (B, )
    @test issetequal(implements(Fox), (A, B))
    @test issetequal(implements(Alligator), (A, B, C))
    @test issetequal(implements(Crocodile), (A, B, C))
end

end
