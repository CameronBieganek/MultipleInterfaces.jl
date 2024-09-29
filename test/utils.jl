

module UtilsTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: all_t, ancestors, delete, filter_t, in_t
using ExtendableInterfaces: intersect_t, map_t, tail, union_t, unique_t


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

function foo(x)
    x == A() ? 1 :
    x == B() ? 2 : 3
end

@testset "utils" begin

    @test all_t(==, (), ())
    @test all_t(!=, (), ())
    @test all_t(==, (A(), ), (A(), ))
    @test !all_t(==, (A(), ), (B(), ))
    @test all_t(==, (A(), B()), (A(), B()))
    @test !all_t(==, (A(), B()), (A(), C()))
    @test all_t(==, (A(), B(), C()), (A(), B(), C()))
    @test !all_t(==, (A(), B(), C()), (A(), B(), D()))

    @test delete((), B()) == ()
    @test delete((A(), B(), C()), B()) == (A(), C())
    @test delete((A(), B(), C()), D()) == (A(), B(), C())

    @test filter_t(==(A()), ()) == ()
    @test filter_t(==(A()), (B(), A(), A(), C())) == (A(), A())
    @test filter_t(!=(A()), (B(), A(), A(), C())) == (B(), C())

    @test in_t(C(), (A(), B(), C()))
    @test !in_t(C(), (A(), B()))
    @test in_t(C(), (C(), ))
    @test !in_t(D(), ())

    @test issetequal(
        intersect_t(
            (A(), B(), C()),
            (B(), C(), D())
        ),
        (B(), C())
    )
    @test (C(), ) == intersect_t(
        (A(), B(), C()),
        (C(), D(), E())
    )
    @test () == intersect_t(
        (A(), B(), C()),
        (D(), E(), F())
    )
    @test intersect_t((), (A(), B())) == ()
    @test intersect_t((A(), B()), ()) == ()
    @test intersect_t((), ()) == ()

    @test map_t(foo, ()) == ()
    @test map_t(foo, (A(), )) == (1, )
    @test map_t(foo, (A(), B())) == (1, 2)
    @test map_t(foo, (A(), B(), C())) == (1, 2, 3)

    @test map_t(==, ()) == ()
    @test map_t(==, (A(), ), (A(), )) == (true, )
    @test map_t(==, (A(), ), (B(), )) == (false, )
    @test map_t(==, (A(), B()), (A(), B())) == (true, true)
    @test map_t(==, (A(), B()), (B(), A())) == (false, false)

    @test tail((A(), B(), C())) == (B(), C())
    @test tail((D(), )) === ()

    @test issetequal(
        union_t(
            (A(), B(), C()),
            (A(), B(), C())
        ),
        (A(), B(), C())
    )
    @test issetequal(
        union_t(
            (A(), B(), C()),
            (B(), C(), D())
        ),
        (A(), B(), C(), D())
    )
    @test issetequal(
        union_t(
            (A(), B(), C()),
            (C(), D(), E())
        ),
        (A(), B(), C(), D(), E())
    )
    @test issetequal(
        union_t(
            (A(), B(), C()),
            (D(), E(), F())
        ),
        (A(), B(), C(), D(), E(), F())
    )
    @test issetequal(
        union_t((), (A(), B())),
        (A(), B())
    )
    @test issetequal(
        union_t((A(), B()), ()),
        (A(), B())
    )
    @test union_t((), ()) == ()

    @test issetequal(
        unique_t((A(), B(), B(), A())),
        (A(), B())
    )
    @test issetequal(
        unique_t((A(), B(), B(), C(), A())),
        (A(), B(), C())
    )
    @test issetequal(
        unique_t((A(), A())),
        (A(), )
    )
    @test unique_t(()) == ()

end

end
