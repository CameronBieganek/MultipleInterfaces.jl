

# For some reason there were some cases of `@inferred` that work under normal
# circumstances but fail inside an `@testset`, so I've moved all the inference tests
# to this top-level script.

module TestInferenceSingleArgumentDispatch

using Test
using ExtendableInterfaces
using ExtendableInterfaces: dispatch

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


# ---- foo ----
@idispatch foo(x: B) = 1
@idispatch foo(x: C) = 2
@idispatch foo(x: E) = 3
@idispatch foo(x: F) = 4

struct Cat end
@type Cat implements B
@type Cat implements E

@inferred dispatch(foo, (Cat(), ))

struct Dog end
@type Dog implements C, D

@inferred dispatch(foo, (Dog(), ))


# ---- bar ----
@idispatch bar(x: A) = 1
@idispatch bar(x: C) = 2
@idispatch bar(x: D) = 3
@idispatch bar(x: E) = 4

struct Bear end
@type Bear implements C
@type Bear implements D
@type Bear implements E

@inferred dispatch(bar, (Bear(), ))

struct Fish end
@type Fish implements C, D

@inferred dispatch(bar, (Fish(), ))


# ---- asdf ----
@idispatch asdf(x: B) = 1
@idispatch asdf(x: D) = 2
@idispatch asdf(x: H) = 3

struct Squid end
@type Squid implements B, D

@inferred dispatch(asdf, (Squid(), ))

struct Crow end
@type Crow implements B
@type Crow implements H

@inferred dispatch(asdf, (Crow(), ))

struct Raven end
@type Raven implements B, E

@inferred dispatch(asdf, (Raven(), ))

struct Goat end
@type Goat implements H

@inferred dispatch(asdf, (Goat(), ))


# ---- qwer ----
@idispatch qwer(x: A) = 1
@idispatch qwer(x: B) = 2
@idispatch qwer(x: C) = 3
@idispatch qwer(x: D) = 4

struct Lizard end
@type Lizard implements A, B, C

@inferred dispatch(qwer, (Lizard(), ))

struct Toad end
@type Toad implements B
@type Toad implements C
@type Toad implements D

@inferred dispatch(qwer, (Toad(), ))

struct Rabbit end
@type Rabbit implements A

@inferred dispatch(qwer, (Rabbit(), ))

struct Eagle end
@type Eagle implements B

@inferred dispatch(qwer, (Eagle(), ))


# -------- Transitive "implements" declarations. --------
function j end
function k end

@interface J begin j end
@interface K begin k end
@interface L extends J, K

@idispatch baz(x: J) = 1

struct Turtle end
@type Turtle implements L

@idispatch aaa(x: J) = 1
@idispatch aaa(x: K) = 2

function m end
function o end
function r end

@interface M begin m end
@interface N extends M
@interface O begin o end
@interface P extends N, O
@interface Q extends P
@interface R begin r end
@interface S extends R

@idispatch bbb(x: M) = 1
@idispatch bbb(x: O) = 2
@idispatch bbb(x: P) = 3
@idispatch bbb(x: R) = 4

struct Frog end
@type Frog implements N
@type Frog implements Q

@inferred dispatch(baz, (Turtle(), ))
@inferred dispatch(bbb, (Frog(), ))
@inferred dispatch(aaa, (Turtle(), ))

end # module
