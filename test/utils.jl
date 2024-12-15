

module UtilsTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: all_t, ancestors, delete, filter_t, foldl_t, in_t
using ExtendableInterfaces: intersect_t, map_t, remove_superinterfaces, tail
using ExtendableInterfaces: transpose_t, union_t, unique_t


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

    @test foldl_t(+, 100, ()) == 100
    @test foldl_t(+, 0, (1, 2, 3, 4)) == 10
    @test foldl_t(tuple, (), ()) == ()
    @test foldl_t(tuple, (), (A(), B(), C())) == ((((), A()), B()), C())
    @test foldl_t(=>, (), (A(), B(), C())) == (((() => A()) => B()) => C())

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

    @test transpose_t(()) == ()
    @test ==(
        transpose_t(
            ((1, 2), )
        ),
        ((1, ), (2, ))
    )
    @test ==(
        transpose_t(
            ((1, ), (2, ), (3, ))
        ),
        ((1, 2, 3), )
    )
    @test ==(
        transpose_t(
            ((1, 2), (3, 4), (5, 6))
        ),
        ((1, 3, 5), (2, 4, 6))
    )
    @test ==(
        transpose_t(
            ((A(), B()), )
        ),
        ((A(), ), (B(), ))
    )
    @test ==(
        transpose_t(
            ((A(), ), (B(), ), (C(), ))
        ),
        ((A(), B(), C()), )
    )
    @test ==(
        transpose_t(
            ((A(), B()), (C(), D()), (E(), F()))
        ),
        ((A(), C(), E()), (B(), D(), F()))
    )

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


@testset "is_subinterface" begin
    @test is_subinterface(C(), A())
    @test is_subinterface(C(), B())
    @test is_subinterface(D(), B())
    @test is_subinterface(E(), C())
    @test is_subinterface(E(), D())
    @test is_subinterface(F(), E())
    @test is_subinterface(G(), F())
    @test is_subinterface(G(), A())
    @test is_subinterface(G(), B())
    @test is_subinterface(F(), D())
    @test is_subinterface(E(), A())
    @test is_subinterface(E(), B())
    @test !is_subinterface(A(), B())
    @test !is_subinterface(B(), A())
    @test !is_subinterface(A(), C())
    @test !is_subinterface(B(), C())
    @test !is_subinterface(D(), A())
    @test !is_subinterface(E(), F())
    @test !is_subinterface(F(), G())
    @test !is_subinterface(E(), G())
    @test !is_subinterface(A(), H())
    @test !is_subinterface(D(), H())
    @test !is_subinterface(H(), B())
    @test !is_subinterface(H(), E())
end


@testset "remove_superinterfaces" begin
    @test remove_superinterfaces((A(), B(), C(), D(), E(), F(), G())) == (G(), )
    @test remove_superinterfaces((G(), F(), E(), D(), C(), B(), A())) == (G(), )
    @test issetequal(
        remove_superinterfaces((A(), B(), C(), D(), E(), F(), G(), H())),
        (G(), H())
    )
    @test issetequal(
        remove_superinterfaces((A(), B(), H())),
        (A(), B(), H())
    )
    @test issetequal(
        remove_superinterfaces((A(), B(), C(), D(), E(), F(), G(), H())),
        (G(), H())
    )
    @test issetequal(
        remove_superinterfaces((A(), B(), C(), D())),
        (C(), D())
    )
    @test (
        remove_superinterfaces((A(), B(), C())) ==
        remove_superinterfaces((B(), A(), C())) ==
        remove_superinterfaces((C(), B(), A())) ==
        (C(), )
    )
    @test remove_superinterfaces((A(), F(), C(), D())) == (F(), )
    @test (
        remove_superinterfaces((E(), G())) ==
        remove_superinterfaces((G(), E())) ==
        (G(), )
    )
end

end
