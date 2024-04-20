

module PolymorphicMacroTests

using ExtendableInterfaces
using Test

@testset "@declare and @polymorphic" begin

    out = @declare foo(a: _)
    @test isnothing(out)
    @test ExtendableInterfaces._polymorphic_methods(foo) == ()

    function a end
    @interface A begin
        a
    end

    out = @polymorphic foo(a: A, b) = a + b
    @test out == foo
    @test ExtendableInterfaces._polymorphic_methods(foo) == (A(), )

end

end
