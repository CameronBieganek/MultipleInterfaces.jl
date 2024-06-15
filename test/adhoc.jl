

module AdhocMacroTests

using ExtendableInterfaces
using Test

@testset "@declare and @adhoc" begin

    out = @declare foo(a: _)
    @test isnothing(out)
    @test ExtendableInterfaces.adhoc_methods(foo) == ()

    function a end
    @interface A begin
        a
    end

    out = @adhoc foo(a: A, b) = a + b
    @test out == foo
    @test ExtendableInterfaces.adhoc_methods(foo) == (A(), )

end

end
