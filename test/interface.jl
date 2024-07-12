

module InterfaceMacroTests

using ExtendableInterfaces
using Test

@testset "@interface" begin

    function a1 end
    function a2 end

    @interface A begin
        a1
        a2
    end

    @test A() === A()
    @test superinterfaces(A()) == ()
    @test issetequal(required_methods(A()), (a1, a2))

    function b1 end
    function b2 end

    @interface B begin
        b1
        b2
    end

    @test B() === B()
    @test superinterfaces(B()) == ()
    @test issetequal(required_methods(B()), (b1, b2))

    function c1 end

    @interface C extends A, B begin
        c1
    end

    @test C() === C()
    @test issetequal(superinterfaces(C()),  (A(), B()))
    @test required_methods(C()) == (c1, )

    function d1 end

    @interface D extends C begin
        d1
    end

    @test D() === D()
    @test issetequal(superinterfaces(D()), (C(), ))
    @test required_methods(D()) == (d1, )

    function e1 end

    @test_throws UndefVarError begin
        @interface E extends Foo, Bar begin
            e1
        end
    end

end

end


module TypeMacroTests

using Test
using ExtendableInterfaces

@testset "@type" begin

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

    @type Cat implements A
    @type Dog implements B
    @type Fox implements A, B
    @type Alligator implements A, B, C

    @test implements(Cat) == (A(), )
    @test implements(Dog) == (B(), )
    @test issetequal(implements(Fox), (A(), B()))
    @test issetequal(implements(Alligator), (A(), B(), C()))

end

end
