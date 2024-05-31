

module ImplementsMacroTests

using Test
using ExtendableInterfaces

@testset "@implements" begin

    function a end
    function b end

    @interface A begin
        a
    end

    @interface B begin
        b
    end

    struct Cat end
    struct Dog end

    @implements Cat: A
    @implements Dog: B

    @test implements(Cat(), A())
    @test implements(Dog(), B())
    @test !implements(Cat(), B())
    @test !implements(Dog(), A())

end

end
