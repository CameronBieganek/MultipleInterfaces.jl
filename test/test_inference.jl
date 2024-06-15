

# For some reason there were some cases of `@inferred` that work under normal
# circumstances but fail inside an `@testset`, so I've moved all the inference tests
# to this top-level script.

module TestInference

using Test
using ExtendableInterfaces
using ExtendableInterfaces: tail, in_tuple, delete, is_subinterface_all
using ExtendableInterfaces: most_specific, SpecificityAmbiguity, dispatch

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

@inferred in_tuple(C(), (A(), B(), C()))
@inferred in_tuple(C(), (A(), B()))

@inferred delete((A(), B(), C()), B())
@inferred delete((A(), B(), C()), D())

@inferred is_subinterface_all(E(), (B(), A()))
@inferred is_subinterface_all(E(), (B(), A(), F()))

@inferred is_subinterface_all(C(), (A(), ))
@inferred is_subinterface_all(A(), (C(), ))

@inferred most_specific((B(), A(), E()))
@inferred most_specific((B(), A(), E(), F()))
@inferred most_specific((B(), F(), A(), E()))
@inferred most_specific((A(), C(), B()))
@inferred most_specific((C(), B(), D()))
@inferred most_specific((A(), G()))
@inferred most_specific((A(), C(), G()))
@inferred most_specific((A(), H()))
@inferred most_specific((A(), C(), H()))


# ---- foo ----
@declare foo(x: _)
@adhoc foo(x: B) = 1
@adhoc foo(x: C) = 2
@adhoc foo(x: E) = 3
@adhoc foo(x: F) = 4

struct Cat end
@implements Cat: B
@implements Cat: E

@inferred dispatch(foo, Cat())
@inferred foo(Cat())

struct Dog end
@implements Dog: C
@implements Dog: D

@inferred dispatch(foo, Dog())
@inferred foo(Dog())


# ---- bar ----
@declare bar(x: _)
@adhoc bar(x: A) = 1
@adhoc bar(x: C) = 2
@adhoc bar(x: D) = 3
@adhoc bar(x: E) = 4

struct Bear end
@implements Bear: C
@implements Bear: D
@implements Bear: E

@inferred dispatch(bar, Bear())
@inferred bar(Bear())

struct Fish end
@implements Fish: C
@implements Fish: D

@inferred dispatch(bar, Fish())


# ---- asdf ----
@declare asdf(x: _)
@adhoc asdf(x: B) = 1
@adhoc asdf(x: D) = 2
@adhoc asdf(x: H) = 3

struct Squid end
@implements Squid: B
@implements Squid: D

@inferred dispatch(asdf, Squid())
@inferred asdf(Squid())

struct Crow end
@implements Crow: B
@implements Crow: H

@inferred dispatch(asdf, Crow())

struct Raven end
@implements Raven: B
@implements Raven: E

@inferred dispatch(asdf, Raven())
@inferred asdf(Raven())

struct Goat end
@implements Goat: H

@inferred dispatch(asdf, Goat())
@inferred asdf(Goat())


# ---- qwer ----
@declare qwer(x: _)
@adhoc qwer(x: A) = 1
@adhoc qwer(x: B) = 2
@adhoc qwer(x: C) = 3
@adhoc qwer(x: D) = 4

struct Lizard end
@implements Lizard: A
@implements Lizard: B
@implements Lizard: C

@inferred dispatch(qwer, Lizard())
@inferred qwer(Lizard())

struct Toad end
@implements Toad: B
@implements Toad: C
@implements Toad: D

@inferred dispatch(qwer, Toad())

struct Rabbit end
@implements Rabbit: A

@inferred dispatch(qwer, Rabbit())
@inferred qwer(Rabbit())

struct Eagle end
@implements Eagle: B

@inferred dispatch(qwer, Eagle())
@inferred qwer(Eagle())

end # module
