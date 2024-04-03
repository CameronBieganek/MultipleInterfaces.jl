
using ExtendableInterfaces
using Test


@testset "@interface" begin

    function a1 end
    function a2 end

    @interface A begin
        a1
        a2
    end

    @test A() == A()
    @test superinterfaces(A()) == ()
    @test requiredmethods(A()) == (a1, a2)

    function b1 end
    function b2 end

    @interface B begin
        b1
        b2
    end

    @test B() == B()
    @test superinterfaces(B()) == ()
    @test requiredmethods(B()) == (b1, b2)

    function c1 end

    @interface C extends A, B begin
        c1
    end

    @test C() == C()
    @test superinterfaces(C()) == (A(), B())
    @test requiredmethods(C()) == (c1, )

    function d1 end

    @interface D extends C begin
        d1
    end

    @test D() == D()
    @test superinterfaces(D()) == (C(), )
    @test requiredmethods(D()) == (d1, )

    function e1 end

    @test_throws UndefVarError begin
        @interface E extends Foo, Bar begin
            e1
        end
    end

end
