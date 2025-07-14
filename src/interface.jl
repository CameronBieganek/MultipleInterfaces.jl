

# This function gets overloaded by the `@interface` macro in the user scope.
function var"-MultipleInterfaces-superinterfaces-" end

# A more convenient name for internal usage.
_superinterfaces(x::ConcreteInterface) = var"-MultipleInterfaces-superinterfaces-"(x)

# The exported version that dispatches on interface types rather than instances.
"""
    superinterfaces(I)

Return a tuple of the superinterfaces of the interface `I`.

This function is not defined for interface intersections.

# Examples
```jldoctest
julia> @interface A begin sin end

julia> @interface B begin cos end

julia> @interface C extends A, B begin
           tan
       end

julia> superinterfaces(C)
(A, B)
```
"""
function superinterfaces(I::Type{<:ConcreteInterface})
    map(typeof, var"-MultipleInterfaces-superinterfaces-"(I()))
end


# This function gets overloaded by the `@interface` macro in the user scope.
function var"-MultipleInterfaces-required_methods-" end

# The exported version that dispatches on interface types rather than instances.
"""
    required_methods(I)

Return an immutable vector containing the fixed list of required methods
for interface `I`.

This function is not defined for interface intersections.

# Examples
```jldoctest
julia> function foo end;

julia> function bar end;

julia> @interface A begin
           foo
           bar
       end

julia> required_methods(A)
2-element MultipleInterfaces.RequiredMethodsVector{Function}:
 foo (generic function with 0 methods)
 bar (generic function with 0 methods)
```
"""
function required_methods(I::Type{<:ConcreteInterface})
    var"-MultipleInterfaces-required_methods-"(I())
end


# TODO: Improve printing of `RequiredMethodsVector`. In particular, the
# parent modules of functions should be included in the function name.
struct RequiredMethodsVector{T} <: AbstractVector{T}
    methods::Vector{T}
end

Base.size(req::RequiredMethodsVector) = size(req.methods)
Base.getindex(req::RequiredMethodsVector, i::Integer) = getindex(req.methods, i)


function interface_helper(name, superinterfaces, methods_block)
    check_methods_block_head(methods_block)

    if any(arg -> !(arg isa LineNumberNode) && !is_name(arg), methods_block.args)
        throw(ArgumentError(
            "Something other than a function name has been provided in the " *
            "list of required methods for an interface."
        ))
    end

    esc_methods = esc.(filter(is_name, methods_block.args))
    isempty(esc_methods) && throw_at_least_one_method_error()

    esc_superinterfaces = map(esc, superinterfaces.args)
    esc_superinterface_objs = map(s -> :($s()), esc_superinterfaces)
    tuple_esc_superinterface_objs = Expr(:tuple, esc_superinterface_objs...)

    esc_name = esc(name)

    quote
        # This will throw an `UndefVarErr` if any of the declared superinterfaces
        # are not yet defined.
        $(esc_superinterfaces...)

        # Ditto for the declared methods of the interface.
        $(esc_methods...)

        struct $esc_name <: ConcreteInterface end

        import MultipleInterfaces: var"-MultipleInterfaces-superinterfaces-"
        import MultipleInterfaces: var"-MultipleInterfaces-required_methods-"

        function $(esc(Symbol("-MultipleInterfaces-superinterfaces-")))(::$esc_name)
            $tuple_esc_superinterface_objs
        end

        function $(esc(Symbol("-MultipleInterfaces-required_methods-")))(::$esc_name)
            RequiredMethodsVector([$(esc_methods...)])
        end

        nothing
    end
end


function throw_method_block_error()
    error("The required methods for an interface must be listed in a `begin` block.")
end


function check_methods_block_head(methods_block)
    methods_block.head == :block || throw_method_block_error()
end


function throw_at_least_one_method_error()
    throw(ArgumentError("An interface must require at least one method."))
end


# We could just leave this undefined and thus get a method error, but macro
# method errors are usually not very informative.
macro interface(name::Symbol)
    throw_method_block_error()
end


macro interface(name::Symbol, methods_block::Expr)
    check_methods_block_head(methods_block)
    length(methods_block.args) < 2 && throw_at_least_one_method_error()
    interface_helper(name, :(()), methods_block)
end

"""
    @interface(args...)

Define a new interface. An interface definition includes a list of methods
that must be defined for a type in order for that type to implement this
interface. Every interface must require at least one method, and all methods
in the list are mandatory.

Use the following syntax to define a new interface `A` with the required methods
`foo` and `bar`:

```julia
@interface A begin
    foo
    bar
end

A new interface can extend one or more existing interfaces. To define a new
interface `B` that extends the interface `A`, use the following syntax:

```julia
@interface B extends A begin
    baz
    qux
end
```

To define a new interface that extends multiple interfaces, provide the extended
interfaces as a comma separated list, like this:

```julia
@interface R extends P, Q begin
    qwer
    asdf
end
```

Note that the functions in the required methods list must already exist or
the `@interface` macro will throw an `UndefVarErr` (and likewise for the list
of interfaces that are being extended).

The required methods of an interface can be inspected with the `required_methods`
function. Interfaces can be dispatched on in special methods that are defined
with the `@idispatch` macro.

# Examples
```jldoctest
julia> function foo end
foo (generic function with 0 methods)

julia> function bar end
bar (generic function with 0 methods)

julia> @interface A begin
           foo
           bar
       end

julia> required_methods(A)
2-element MultipleInterfaces.RequiredMethodsVector{Function}:
 foo (generic function with 0 methods)
 bar (generic function with 0 methods)
```
"""
macro interface(name::Symbol, extends::Symbol, superinterfaces::Union{Symbol, Expr}, methods_block)
    if extends !== :extends
        error("Use `extends` syntax to make a subinterface, like `@interface C extends A, B`.")
    end

    if is_name(superinterfaces)
        superinterfaces = :(($superinterfaces, ))
    else
        if superinterfaces.head != :tuple || any(!is_name, superinterfaces.args)
            error(
                "The superinterfaces must be provided as a comma-separated list, like " *
                "`@interface C extends A, B`."
            )
        end
    end

    interface_helper(name, superinterfaces, methods_block)
end


# TODO: Rewrite the `@interface` macro to use only a single method, like `@interface(exs...)`.


macro interface(name::Symbol, extends::Symbol, superinterfaces::Union{Symbol, Expr})
    throw_method_block_error()
end


macro interface(exs...)
    error("Syntax error in the `@interface` macro.")
end


# This function gets overloaded by the `@type` macro in the user scope.
var"-MultipleInterfaces-implements-"(::Type) = ()

# A more convenient name for internal usage.
_implements(T::Type) = var"-MultipleInterfaces-implements-"(T)
_implements(::T) where {T} = _implements(T)

# The exported version. Returns interface types rather than instances.
"""
    implements(T::Type)

Return a tuple of the interfaces implemented by the type `T`.

# Examples
```jldoctest
julia> function a end;

julia> @interface A begin a end

julia> struct Ant end

julia> @type Ant implements A

julia> implements(Ant)
(A,)
```
"""
implements(T::Type) = map(typeof, _implements(T))


function throw_type_macro_syntax_error()
    error(
        "Syntax error in `@type`. To declare that type `Foo` implements interfaces" *
        "`A` and `B`, write `@type Foo implements A, B`."
    )
end


# This function is not part of the dispatch machinery, so it does not need to compile away.
# This function returns all (possibly transitive) superinterfaces of
# `interface`, including `interface`.
function ancestors(interface::ConcreteInterface)
    visited = ()
    stack = ConcreteInterface[interface]

    while !isempty(stack)
        interface = pop!(stack)
        if !in_t(interface, visited)
            visited = (visited..., interface)
            for superinterface in _superinterfaces(interface)
                push!(stack, superinterface)
            end
        end
    end

    visited
end


"""
    all_required_methods(I)

Return an immutable vector containing the fixed set of required methods
in interface `I` and all the superinterfaces of `I`. This provides the
complete list of methods that must be implemented by a type in order
to implement the interface `I`.

This function is not defined for interface intersections.

# Examples
```jldoctest
julia> function a end;

julia> function b end;

julia> function c end;

julia> @interface A begin a end

julia> @interface B begin b end

julia> @interface C extends A, B begin
           c
       end

julia> required_methods(C)
1-element MultipleInterfaces.RequiredMethodsVector{typeof(c)}:
 c (generic function with 0 methods)

julia> all_required_methods(C)
3-element MultipleInterfaces.RequiredMethodsVector{Function}:
 a (generic function with 0 methods)
 b (generic function with 0 methods)
 c (generic function with 0 methods)
```
"""
function all_required_methods(T::Type{<:ConcreteInterface})
    superinterfaces = ancestors(T()) # Never empty, because `T()` is included.
    methods = mapreduce(required_methods ∘ typeof, union, superinterfaces)
    RequiredMethodsVector(sort(methods, by=string))
end


function update_implemented(::Type{T}, new_impls::Tuple) where {T}
    foldl(new_impls; init=_implements(T)) do implemented, new_impl
        union_t(implemented, ancestors(new_impl))
    end
end


"""
    @type(args...)

Declare that a type implements one or more interfaces. To declare that the
type `Foo` implements the interface `A`, use the following syntax:

```julia
@type Foo implements A
```

More than one interface implementation for a type can be declared in the
same `@type` declaration, by providing a comma-separated list of interfaces,
like this:

```julia
@type Bar implements B, C
```

Note that declaring that a type implements an interface implies that the
type also implements all the superinterfaces of that interface. For example,
if `Y` is a subinterface of `X`, then `@type Qux implements Y` declares
that `Qux` implements both `Y` and `X`.

The interfaces implemented by a type can be queried with the `implements`
function.

# Examples
```jldoctest
julia> function a end;

julia> function b end;

julia> @interface A begin a end

julia> @interface B extends A begin
           b
       end

julia> struct Foo end

julia> @type Foo implements B

julia> implements(Foo)
(B, A)
```
"""
macro type(type, implements::Symbol, interfaces_list_ex)
    type = esc(type)

    implements != :implements && throw_type_macro_syntax_error()

    if is_name(interfaces_list_ex)
        interface_exs = [interfaces_list_ex]
    elseif interfaces_list_ex.head == :tuple
        if all(is_name, interfaces_list_ex.args)
            interface_exs = interfaces_list_ex.args
        else
            throw_type_macro_syntax_error()
        end
    else
        throw_type_macro_syntax_error()
    end

    esc_interface_objs = map(ex -> :($(esc(ex))()), interface_exs)

    quote
        import MultipleInterfaces: var"-MultipleInterfaces-implements-"

        if isabstracttype($type)
            throw(ArgumentError("Cannot declare that an abstract type implements an interface."))
        else
            let
                global var"-MultipleInterfaces-implements-"

                implemented = update_implemented($type, ($(esc_interface_objs...), ))

                function $(esc(Symbol("-MultipleInterfaces-implements-")))(::Type{<:$type})
                    implemented
                end
            end
        end

        nothing
    end
end
