

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
