

module InterfaceMacroTests

using ExtendableInterfaces
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
    @test issetequal(required_methods(A), (a1, a2))

    @test B() === B()
    @test superinterfaces(B) == ()
    @test issetequal(required_methods(B), (b1, b2))

    @test C() === C()
    @test issetequal(superinterfaces(C), (A, B))
    @test required_methods(C) == (c1, )

    @test D() === D()
    @test issetequal(superinterfaces(D), (C, ))
    @test required_methods(D) == (d1, )
end

end



module AncestorsTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: ancestors

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
using ExtendableInterfaces


function a end
function b end

@interface A begin
    a
end

@interface B begin
    b
end

@interface C extends A, B

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
    @test implements(Cat) == (A(), )
    @test implements(Dog) == (B(), )
    @test issetequal(implements(Fox), (A(), B()))
    @test issetequal(implements(Alligator), (A(), B(), C()))
    @test issetequal(implements(Crocodile), (A(), B(), C()))
end

end
