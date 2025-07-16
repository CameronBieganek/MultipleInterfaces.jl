# MultipleInterfaces.jl


## Introduction

MultipleInterfaces.jl provides a powerful way to define and work with interfaces in Julia. With
MultipleInterfaces.jl you can declare an interface that is defined by a list of required methods,
and you can declare which types implement that interface. Interfaces support multiple inheritance,
interface intersection, and multiple dispatch. And all with no runtime cost.


## Defining an interface

Interfaces are defined with the `@interface` macro. The `@interface` macro takes a name
and a list of required methods, like this:

```julia
using MultipleInterfaces

function a1 end
function a2 end

@interface A begin
    a1
    a2
end
```

In order for a type to implement an interface, it must define a method for each of the functions
listed in the `@interface` declaration. The required methods for an interface can be queried with
the `required_methods` function, like this:

```julia
julia> required_methods(A)
2-element MultipleInterfaces.RequiredMethodsVector{Function}:
 a1 (generic function with 0 methods)
 a2 (generic function with 0 methods)
```

To define an interface `B` that extends `A`, we can use the `@interface` macro like this:

```julia
function b end

@interface B extends A begin
    b
end
```

When a new interface extends an old interface, it means that the new interface requires all the
methods of the old interface plus all the new methods required by the new interface. So, in the
above example, a type that implements interface `A` must implement methods for `a1` and `a2`. A
type that implements interface `B` must implement methods for `a1`, `a2`, and `b`.

When the `required_methods` function is called on an interface, it only returns the method
requirements that are introduced by the corresponding `@interface` declaration. To get the full
list of all transitive method requirements for an interface, use the `all_required_methods`
function, as demonstrated below:

```julia
julia> required_methods(B)
1-element MultipleInterfaces.RequiredMethodsVector{typeof(b)}:
 b (generic function with 0 methods)

julia> all_required_methods(B)
3-element MultipleInterfaces.RequiredMethodsVector{Function}:
 a1 (generic function with 0 methods)
 a2 (generic function with 0 methods)
 b (generic function with 0 methods)
```

There are no optional methods in an interface. However, this is not generally an issue, because
MultipleInterfaces.jl allows interfaces to extend multiple interfaces. This allows interface
designers to design a rich DAG of interfaces that captures the different combinations and extensions
of interfaces that make semantic sense.

To define an interface `D` that extends both `B` and `C`, we would write
`@interface D extends B, C`, like in the following example:

```julia
function c end

@interface C begin
    c
end

function d end

@interface D extends B, C begin
    d
end
```

The interfaces that an interface directly extends are called the "superinterfaces". The
superinterfaces of an interface can be retrieved with the `superinterfaces` function, like this:

```julia-repl
julia> superinterfaces(A)
()

julia> superinterfaces(B)
(A,)

julia> superinterfaces(C)
()

julia> superinterfaces(D)
(B, C)
```

In truth, MultipleInterfaces.jl does not enforce that a type that has implemented an interface has
implemented all the required methods for that interface. The requirement to provide a list
of methods when defining an interface is to encourage clear, well designed interfaces and to make
it easy to discover the requirements of an interface with `required_methods` and
`all_required_methods`. If you wish to test that an interface has been correctly implemented, we
recommend [Supposition.jl](https://github.com/Seelengrab/Supposition.jl). Interface authors are
encouraged to provide interface test suites based on Supposition.jl.


## Declaring an interface implementation

To declare that a type implements an interface, use the `@type` macro, with the syntax
`@type <type> implements <list of interfaces>`, as demonstrated below:

```julia
struct Ant end

@type Ant implements A
```

You can declare that a type implements multiple interfaces in a singe `@type` declaration, like
this:

```julia
struct Mouse end

@type Mouse implements B, C
```

For a type to properly implement an interface, it must implement the required methods for that
interface and for all interfaces that are extended by that interface. (The complete list of
methods required to implement an interface can be queried with the `all_required_methods`
function.) So, since `B` extends `A`, the declaration `@type Foo implements B` is equivalent to
the declaration `@type Foo implements A, B`.

The list of interfaces implemented by a type can be retrieved with the `implements` function,
like this:

```julia
julia> implements(Ant)
(A,)

julia> implements(Mouse)
(B, A, C)
```

As alluded to in the previous section, the `@type` macro only declares an implementation; it does
not enforce it. However, if you don't fully implement an interface that you've declared that you've
implemented, then you will likely get errors from functions that assume the interface has been
fully implemented.


## Defining methods that dispatch on interfaces

MultipleInterfaces.jl provides the ability to define methods that dispatch on both types and
interfaces. We refer to these methods as i-methods to distinguish them from regular methods.
The name "i-method" is short for "interface dispatch method". I-methods can be defined with
the `@idispatch` macro, as shown in this example:

```julia
@idispatch foo(x: A) = 1
@idispatch foo(x: B) = 2
@idispatch foo(x: C) = 3
```

Let's define a couple types that implement `B` and `C`:

```julia
struct Bear end
struct Cat end

@type Bear implements B
@type Cat implements C
```

Now let's see the i-methods in action:

```julia
julia> foo(Ant())
1

julia> foo(Bear())
2

julia> foo(Cat())
3
```

In the example above, the i-method dispatch behaves the same as regular type-based dispatch.
However, since interfaces allow multiple inheritance, it is possible to have an ambiguity in the
dispatch on a single argument. Observe what happens when we call `foo` on a `Mouse`:

```julia-repl
julia> foo(Mouse())
ERROR: SingleArgumentAmbiguityError: There is a single argument i-dispatch ambiguity.
Stacktrace:
 [1] var"-idispatch-foo(_)-"(::MultipleInterfaces.SingleArgumentAmbiguity, x::Mouse)
   @ Main ~/projects/MultipleInterfaces.jl/src/dispatch.jl:250
 [2] foo(x::Mouse)
   @ Main ~/projects/MultipleInterfaces.jl/src/dispatch.jl:242
 [3] top-level scope
   @ REPL[11]:1
```

The `Mouse` type implements both the `B` interface and the `C` interface, so the `foo(Mouse())`
call matches both the `foo(x: B)` i-method and the `foo(x: C)` i-method. However, neither of those
methods is more specific than the other, since `B` is not an extension of `B` and `C` is not
an extension of `C`. (Alternatively, we could say that `B` is not a subinterface of `C` and
`C` is not a subinterface of `B`.) So, since there is not matching method that is most specific,
MultipleInterfaces.jl throws a `SingleArgumentAmbiguityError`.

It's also possible to have a `MultipleArgumentAmbiguityError`, but those are equivalent to the
[ambiguity errors that can happen with standard Julia methods](https://docs.julialang.org/en/v1/manual/methods/#man-ambiguities)
that have more than one argument.

I-methods support multiple dispatch and can dispatch on both types and interfaces. Additionally,
i-methods also support dispatching on interface intersections. Interface intersections are defined
with the `&` operator. A type matches an interface intersection if it implements all the interfaces
in the intersection. So, for example, the `Mouse` type matches the `B & C` interface intersection.

Here's an example of a more complicated i-method:

```julia
@idispatch foo(w::Int, x: A, y::String, z: B & C) = 4
```

And here we see it in action:

```julia-repl
julia> foo(42, Ant(), "hello", Mouse())
4
```

An i-method first dispatches on the type arguments, and then on the interface arguments. For the
initial dispatch on the type arguments, the interface arguments are treated as having type `Any`.
So, if you define a method `bar(x) = 1` and then you define an i-method `@idispatch bar(x: A) = 2`,
the i-method definition will overwrite the previous `bar(x)` method.


## Interface intersections

Any number of interfaces can be intersected together, like `A & B & C`. Interface intersections
are automatically simplified, as can be seen in the following example:

```julia-repl
julia> A & A
A

julia> A & A & A
A

julia> A & B
B

julia> A & B & C
B & C

julia> A & B & C & D
D

julia> A & B & C & D & D & C & B & A
D
```

The order in which interfaces are intersected does not matter:

```julia-repl
julia> B & C == C & B
true
```


# `is_subinterface` (`≼`)

If interface `B` extends interface `A` (either directly or indirectly), we say that `B` is a
"subinterface" of `A`. (Note that an interface is also considered to be a subinterface of itself.)
You can test the subinterface relationship between two interfaces with the `is_subinterface`
function. The `is_subinterface` function has a binary operator form, `≼`, which can be typed as
`\preccurlyeq<tab>`. Here is an example, continuing the examples from above:

```julia-repl
julia> B ≼ A
true

julia> A ≼ B
false

julia> C ≼ A
false

julia> D ≼ A
true
```

`is_subinterface` also works with intersection types. Note that if you add an interface to an
intersection, the new intersection is more specific than the previous intersection. So, for example,
`S & T & U ≼ S & T`. Here are some more examples that make use of the interfaces defined above:

```julia-repl
julia> function h end;

julia> @interface H begin h end

julia> A ≼ A
true

julia> A & C ≼ A
true

julia> A ≼ C & A
false

julia> B & C ≼ B
true

julia> B & C ≼ C
true

julia> B & C & H ≼ B & C
true
```

The `⋠` operator is also provided, which is equivalent to `!is_subinterface`. This operator can
be typed as `\npreccurlyeq<tab>`.


## Alternative packages

There are a number of registered Julia packages that deal with interfaces or traits. Here is
a partial list:

- [Interfaces.jl](https://github.com/rafaqz/Interfaces.jl)
- [RequiredInterfaces.jl](https://github.com/Seelengrab/RequiredInterfaces.jl)
- [SimpleTraits.jl](https://github.com/mauro3/SimpleTraits.jl)
- [BinaryTraits.jl](https://github.com/tk3369/BinaryTraits.jl)
- [WhereTraits.jl](https://github.com/jolin-io/WhereTraits.jl)
