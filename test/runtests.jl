
using ExtendableInterfaces
using Test


@testset "@interface" begin

    function bar end
    function baz end

    @interface Foo begin
        bar
        baz
    end

    @test Foo() == Foo()
    @test superinterfaces(Foo()) == ()
    @test requiredmethods(Foo()) == (bar, baz)

end
