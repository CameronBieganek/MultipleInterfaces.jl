

# For some reason there were some cases of `@inferred` that work under normal
# circumstances but fail inside an `@testset`, so I've moved all the inference tests
# to this top-level script.

module TestInferenceSingleArgumentDispatch

using Test
using ExtendableInterfaces
using ExtendableInterfaces: dispatch

function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end
@interface D extends B begin d end
@interface E extends C, D begin e end
@interface F extends E begin f end
@interface G extends F begin g end

# Isolated node in interface DAG.
@interface H begin h end


# ---- foo ----
@idispatch foo(x: B) = 1
@idispatch foo(x: C) = 2
@idispatch foo(x: E) = 3
@idispatch foo(x: F) = 4

struct Cat end
@type Cat implements B
@type Cat implements E

@inferred dispatch(var"-idispatch-foo(_)-", (Cat(), ))

struct Dog end
@type Dog implements C, D

@inferred dispatch(var"-idispatch-foo(_)-", (Dog(), ))


# ---- bar ----
@idispatch bar(x: A) = 1
@idispatch bar(x: C) = 2
@idispatch bar(x: D) = 3
@idispatch bar(x: E) = 4

struct Bear end
@type Bear implements C
@type Bear implements D
@type Bear implements E

@inferred dispatch(var"-idispatch-bar(_)-", (Bear(), ))

struct Fish end
@type Fish implements C, D

@inferred dispatch(var"-idispatch-bar(_)-", (Fish(), ))


# ---- asdf ----
@idispatch asdf(x: B) = 1
@idispatch asdf(x: D) = 2
@idispatch asdf(x: H) = 3

struct Squid end
@type Squid implements B, D

@inferred dispatch(var"-idispatch-asdf(_)-", (Squid(), ))

struct Crow end
@type Crow implements B
@type Crow implements H

@inferred dispatch(var"-idispatch-asdf(_)-", (Crow(), ))

struct Raven end
@type Raven implements B, E

@inferred dispatch(var"-idispatch-asdf(_)-", (Raven(), ))

struct Goat end
@type Goat implements H

@inferred dispatch(var"-idispatch-asdf(_)-", (Goat(), ))


# ---- qwer ----
@idispatch qwer(x: A) = 1
@idispatch qwer(x: B) = 2
@idispatch qwer(x: C) = 3
@idispatch qwer(x: D) = 4

struct Lizard end
@type Lizard implements A, B, C

@inferred dispatch(var"-idispatch-qwer(_)-", (Lizard(), ))

struct Toad end
@type Toad implements B
@type Toad implements C
@type Toad implements D

@inferred dispatch(var"-idispatch-qwer(_)-", (Toad(), ))

struct Rabbit end
@type Rabbit implements A

@inferred dispatch(var"-idispatch-qwer(_)-", (Rabbit(), ))

struct Eagle end
@type Eagle implements B

@inferred dispatch(var"-idispatch-qwer(_)-", (Eagle(), ))


# -------- Transitive "implements" declarations. --------
function j end
function k end
function l end

@interface J begin j end
@interface K begin k end
@interface L extends J, K begin l end

@idispatch baz(x: J) = 1

struct Turtle end
@type Turtle implements L

@idispatch aaa(x: J) = 1
@idispatch aaa(x: K) = 2

function m end
function n end
function o end
function p end
function q end
function r end
function s end

@interface M begin m end
@interface N extends M begin n end
@interface O begin o end
@interface P extends N, O begin p end
@interface Q extends P begin q end
@interface R begin r end
@interface S extends R begin s end

@idispatch bbb(x: M) = 1
@idispatch bbb(x: O) = 2
@idispatch bbb(x: P) = 3
@idispatch bbb(x: R) = 4

struct Frog end
@type Frog implements N
@type Frog implements Q

@inferred dispatch(var"-idispatch-baz(_)-", (Turtle(), ))
@inferred dispatch(var"-idispatch-bbb(_)-", (Frog(), ))
@inferred dispatch(var"-idispatch-aaa(_)-", (Turtle(), ))

end # module




####################################################################################################

module MultipleDispatchInferrenceTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: dispatch

function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

# A -> B -> C -> D
@interface A begin a end
@interface B extends A begin b end
@interface C extends B begin c end
@interface D extends C begin d end

# E -> F -> G -> H
@interface E begin e end
@interface F extends E begin f end
@interface G extends F begin g end
@interface H extends G begin h end

@idispatch foo(x::Int, b: B, f: F) = 1
@idispatch foo(x::Int, d: D, h: H) = 2
@idispatch foo(x::String, b: B, f: F) = 3
@idispatch foo(x::String, d: D, h: H) = 4

struct Ant end
struct Cat end
struct Dog end
struct Elephant end
struct Gerbal end
struct Hamster end

@type Ant implements A
@type Cat implements C
@type Dog implements D
@type Elephant implements E
@type Gerbal implements G
@type Hamster implements H

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Hamster()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Dog(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Dog(), Hamster()))
@inferred dispatch(var"-idispatch-foo(String,_,_)-", (Cat(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(String,_,_)-", (Cat(), Hamster()))
@inferred dispatch(var"-idispatch-foo(String,_,_)-", (Dog(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(String,_,_)-", (Dog(), Hamster()))

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Cat()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Dog()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Dog(), Cat()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Dog(), Dog()))

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Gerbal(), Cat()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Gerbal(), Dog()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Hamster(), Cat()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Hamster(), Dog()))

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Gerbal(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Gerbal(), Hamster()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Hamster(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Hamster(), Hamster()))

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Ant(), Elephant()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Ant(), Gerbal()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Ant(), Hamster()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Elephant()))
@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Dog(), Elephant()))

end



####################################################################################################

module MultipleDispatchSingleArgumentAmbiguityTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: dispatch

function a end
function b end
function c end

function m end
function n end

function p end
function q end
function r end

@interface A begin a end
@interface B extends A begin
    b
end
@interface C extends A begin
    c
end

@interface M begin m end
@interface N extends M begin
    n
end

@interface P begin p end
@interface Q extends P begin
    q
end
@interface R extends P begin
    r
end

@idispatch foo(x::Int, a: A, m: M) = 1
@idispatch foo(x::Int, b: B, m: M) = 2
@idispatch foo(x::Int, c: C, m: M) = 3

@idispatch bar(x::Int, a: A, p: P) = 1
@idispatch bar(x::Int, b: B, q: Q) = 2
@idispatch bar(x::Int, c: C, r: R) = 3

struct Cat end
struct Dog end
struct Horse end

@type Cat implements B, C
@type Dog implements N
@type Horse implements Q, R

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Dog()))
@inferred dispatch(var"-idispatch-bar(Int,_,_)-", (Cat(), Horse()))

end



####################################################################################################

module MultipleDispatchMultipleArgumentAmbiguityTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: dispatch

function a end
function b end

function p end
function q end

# A -> B
@interface A begin a end
@interface B extends A begin
    b
end

# P -> Q
@interface P begin p end
@interface Q extends P begin
    q
end

@idispatch foo(x::Int, a: A, p: P) = 1
@idispatch foo(x::Int, b: B, p: P) = 2
@idispatch foo(x::Int, a: A, q: Q) = 3

struct Cat end
struct Dog end

@type Cat implements B
@type Dog implements Q

@inferred dispatch(var"-idispatch-foo(Int,_,_)-", (Cat(), Dog()))

end



####################################################################################################

module ComplicatedMultipleDispatchTests

using Test
using ExtendableInterfaces
using ExtendableInterfaces: dispatch

function a end
function b end
function c end
function d end
function e end
function f end
function g end
function h end

@interface A begin a end
@interface B begin b end
@interface C extends A, B begin c end
@interface D extends B begin d end
@interface E extends C, D begin e end
@interface F extends E begin f end
@interface G extends F begin g end

# Isolated node in interface DAG.
@interface H begin h end

function m end
function n end
function o end
function p end
function q end
function r end
function s end
function t end

@interface M begin m end
@interface N begin n end
@interface O begin o end
@interface P extends M, N begin p end
@interface Q extends N, O begin q end
@interface R extends P begin r end
@interface S extends P, Q begin s end
@interface T extends Q begin t end

struct Cat end
struct Dog end
struct Fox end
struct Horse end
struct Newt end
struct Parrot end
struct Salamander end
struct Tiger end

struct Chameleon end

@type Cat implements C
@type Dog implements D
@type Fox implements F
@type Horse implements H
@type Newt implements N
@type Parrot implements P
@type Salamander implements S
@type Tiger implements T

@type Chameleon implements F, S

@idispatch foo(c: C, x::String, n: N) = 1
@idispatch foo(c: E, x::String, n: N) = 2
@idispatch foo(c: F, x::String, p: P) = 3
@idispatch foo(c: G, x::String, n: N) = 4

@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Cat(), Newt()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Cat(), Parrot()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Cat(), Salamander()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Cat(), Tiger()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Cat(), Chameleon()))

@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Fox(), Tiger()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Fox(), Newt()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Chameleon(), Tiger()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Chameleon(), Newt()))

@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Dog(), Newt()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Dog(), Parrot()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Dog(), Salamander()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Dog(), Tiger()))

@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Fox(), Parrot()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Fox(), Salamander()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Chameleon(), Parrot()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Chameleon(), Salamander()))
@inferred dispatch(var"-idispatch-foo(_,String,_)-", (Chameleon(), Chameleon()))

@idispatch bar(h: H) = 1

@inferred dispatch(var"-idispatch-bar(_)-", (Horse(), ))
@inferred dispatch(var"-idispatch-bar(_)-", (Cat(), ))
@inferred dispatch(var"-idispatch-bar(_)-", (Fox(), ))
@inferred dispatch(var"-idispatch-bar(_)-", (Salamander(), ))
@inferred dispatch(var"-idispatch-bar(_)-", (Tiger(), ))
@inferred dispatch(var"-idispatch-bar(_)-", (Chameleon(), ))

@idispatch asdf(x::Int, n: N, e: E) = 1
@idispatch asdf(x::Int, p: P, e: E) = 2
@idispatch asdf(x::Int, q: Q, e: E) = 3

struct Rooster end
@type Rooster implements P, Q

@inferred dispatch(var"-idispatch-asdf(Int,_,_)-", (Newt(), Fox()))
@inferred dispatch(var"-idispatch-asdf(Int,_,_)-", (Newt(), Fox()))
@inferred dispatch(var"-idispatch-asdf(Int,_,_)-", (Parrot(), Fox()))
@inferred dispatch(var"-idispatch-asdf(Int,_,_)-", (Rooster(), Fox()))

@idispatch qwer(c: C, p: P, x::Char) = 1
@idispatch qwer(f: F, p: P, x::Char) = 2
@idispatch qwer(c: C, s: S, x::Char) = 3

@inferred dispatch(var"-idispatch-qwer(_,_,Char)-", (Cat(), Parrot()))
@inferred dispatch(var"-idispatch-qwer(_,_,Char)-", (Fox(), Parrot()))
@inferred dispatch(var"-idispatch-qwer(_,_,Char)-", (Cat(), Salamander()))
@inferred dispatch(var"-idispatch-qwer(_,_,Char)-", (Fox(), Salamander()))

end
