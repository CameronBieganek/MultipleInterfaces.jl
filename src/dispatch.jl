

struct NoMatchingIDispatchMethod end
struct SingleArgumentAmbiguity end
struct MultipleArgumentAmbiguity end


"""
    NoMatchingIDispatchMethodError

There is no i-method with a signature matching the arguments provided to
an i-method function call.
"""
struct NoMatchingIDispatchMethodError <: Exception end

"""
    SingleArgumentAmbiguityError

In a call to an i-method, there is an argument for which there is no
most specific dispatched upon interface among the matching i-methods.
"""
struct SingleArgumentAmbiguityError <: Exception end

"""
    MultipleArgumentAmbiguityError

There is a multiple-argument method ambiguity in an i-method.
"""
struct MultipleArgumentAmbiguityError <: Exception end


# TODO: Improve the error messages.

function Base.showerror(io::IO, ::NoMatchingIDispatchMethodError)
    print(io, "NoMatchingIDispatchMethodError: No matching i-dispatch method.")
end

function Base.showerror(io::IO, ::SingleArgumentAmbiguityError)
    print(io, "SingleArgumentAmbiguityError: There is a single argument i-dispatch ambiguity.")
end

function Base.showerror(io::IO, ::MultipleArgumentAmbiguityError)
    print(io, "MultipleArgumentAmbiguityError: There is a multiple argument i-dispatch ambiguity.")
end


# This function gets overloaded by the `@idispatch` macro in the user scope.
var"-MultipleInterfaces-signatures-"(f) = Tuple[]

# A more convenient name for internal usage.
signatures(f) = var"-MultipleInterfaces-signatures-"(f)

is_signature_defined(f, signature) = (signature in signatures(f))


# This function gets overloaded by the `@idispatch` macro in the user scope.
# Return a tuple of signature tuples, where each signature tuple indicates the
# interfaces that are dispatched on for one i-dispatch method.
var"-MultipleInterfaces-interface_signatures-"(f) = ()

# A more convenient name for internal usage.
interface_signatures(f) = var"-MultipleInterfaces-interface_signatures-"(f)


struct InterfaceArg end


throw_idispatch_syntax_error() = error("Syntax error in the `@idispatch` macro.")


is_intersection_ex(::Any) = false

function is_intersection_ex(ex::Expr)
    (
        ex.head == :call
        && ex.args[1] == :&
        && (is_name(ex.args[2]) || is_intersection_ex(ex.args[2]))
        && (is_name(ex.args[3]) || is_intersection_ex(ex.args[3]))
    )
end


"""
    @idispatch(args...)

Define an i-method (an interface method), which can dispatch on both
types and interfaces. An argument `x` that dispatches on an interface
`A` is written as `x: A`. So, to define an i-method that dispatches
on the interface `A` in the first argument and on an `Int` in the
second argument, use the following syntax:

```julia
@idispatch foo(x: A, y::Int) = 42
```

Any combination of type dispatch and interface dispatch can be used,
as long as each argument uses only type dispatch or interface dispatch.
Dispatch on interface intersections, like `B & C`, is also allowed, as
can be seen in the following example:

```julia
@idispatch function qux(w: A, x::Int, y: B & C, z::Float64)
    w + x + y + z
end
```

An i-method first dispatches on the type arguments, and then on the
interface arguments. For the initial dispatch on the type arguments,
the interface arguments are treated as having type `Any`. So, if
you define a method `bar(x) = 1` and then you define an i-method
`@idispatch bar(x: A) = 2`, the i-method definition will overwrite
the previous `bar(x)` method.

# Examples
```jldoctest
julia> function a end; function b end; function c end; function d end;

julia> @interface A begin a end; @interface B extends A begin b end

julia> @interface C begin c end; @interface D begin d end

julia> struct Ant end; struct Bear end; struct Mouse end

julia> @type Ant implements A; @type Bear implements B; @type Mouse implements C, D

julia> @idispatch foo(x::Int, y: A, z: C & D) = 1
foo (generic function with 1 method)

julia> @idispatch foo(x::Int, y: B, z: C & D) = 2
foo (generic function with 1 method)

julia> foo(42, Ant(), Mouse())
1

julia> foo(42, Bear(), Mouse())
2

julia> foo(42, Mouse(), Ant())
ERROR: No matching i-dispatch method.
```
"""
macro idispatch(fdef)
    fdef.head in (:function, :(=)) || throw_idispatch_syntax_error()

    call = fdef.args[1]
    body = fdef.args[2]

    # TODO: Support `where` syntax.
    if call.head != :call || body.head != :block
        throw_idispatch_syntax_error()
    end

    f_name_sym = call.args[1]
    f_name = esc(f_name_sym)
    signature_ex = call.args[2:end]
    n_args = length(signature_ex)

    # Nomenclature
    # ...given the input `foo(x::Foo, a: A, y::Bar, b: B)`
    #
    # signature:                 [esc(:Foo), :InterfaceArg, esc(:Bar), :InterfaceArg]
    # underscore_signature:      [:Foo, :_, :Bar, :_]
    # underscore_signature_str:  "(Foo,_,Bar,_)"
    # normalized_signature_ex:   [:(x::esc(Foo)), :a, :(y::esc(Bar)), :b]
    # arg_names:                 [:x, :a, :y, :b]
    # interface_signature:       [esc(:A), esc(:B)]
    # interface_arg_names:       [:a, :b]
    # interface_objects:         [:($(esc(:A)())), :($(esc(:B)()))]

    signature = Vector{Any}(undef, n_args)
    underscore_signature = Vector{Symbol}(undef, n_args)
    normalized_signature_ex = Vector{Any}(undef, n_args)

    arg_names = Symbol[]
    interface_arg_names = Symbol[]
    interface_signature = Expr[]   # Escaped symbols.
    interface_objects   = Expr[]

    for (i, arg_ex) in enumerate(signature_ex)
        if arg_ex isa Symbol
            name = normalized_arg = arg_ex
            type = underscore_type = :Any
            push!(arg_names, name)
        elseif arg_ex.head == :(::)
            if length(arg_ex.args) == 1
                # This is for handling the first argument in this case:
                # @idispatch foo(::Int, x: A) = 1
                type_sym = arg_ex.args[1]
                type = esc(type_sym)
                underscore_type = type_sym
                normalized_arg = :(::$type)
            else
                name = arg_ex.args[1]
                type_sym = arg_ex.args[2]

                type = esc(type_sym)
                underscore_type = type_sym
                
                push!(arg_names, name)
                normalized_arg = :($name::$type)
            end
        elseif arg_ex.head == :call
            if (
                arg_ex.args[1] == :(:) &&
                arg_ex.args[2] isa Symbol
            )
                type = :InterfaceArg
                underscore_type = :_
                name = normalized_arg = arg_ex.args[2]

                push!(arg_names, name)
                push!(interface_arg_names, name)

                interface_ex = arg_ex.args[3]
                if is_name(interface_ex)
                    push!(interface_signature, esc(interface_ex))
                    push!(interface_objects, :($(esc(interface_ex))()))
                elseif is_intersection_ex(interface_ex)
                    esc_interface_ex = esc(interface_ex)
                    arg_signature = :(typeof($esc_interface_ex))
                    push!(interface_signature, arg_signature)
                    push!(interface_objects, esc_interface_ex)
                else
                    throw_idispatch_syntax_error()
                end
            else
                throw_idispatch_syntax_error()
            end
        else
            throw_idispatch_syntax_error()
        end

        signature[i] = type
        underscore_signature[i] = underscore_type
        normalized_signature_ex[i] = normalized_arg
    end

    # TODO: Can the way that we create the hidden function names cause collisions
    # if the user defines two methods like this?
    #
    # @idispatch foo(x: ModA.Bar) = 1
    # @idispatch foo(x: ModB.Bar) = 2

    underscore_signature_str = "(" * join(underscore_signature, ",") * ")"
    _f_name = esc(Symbol("-idispatch-$f_name_sym$underscore_signature_str-"))

    quote
        if (
            !isdefined(@__MODULE__, $(QuoteNode(f_name_sym))) ||
            !is_signature_defined($f_name, ($(signature...), ))
        )
            function $f_name($(normalized_signature_ex...))
                dispatch_to = dispatch($_f_name, ($(interface_arg_names...), ))
                $_f_name(dispatch_to, $(arg_names...))
            end

            function $_f_name(::NoMatchingIDispatchMethod, $(arg_names...))
                throw(NoMatchingIDispatchMethodError())
            end

            function $_f_name(::SingleArgumentAmbiguity, $(arg_names...))
                throw(SingleArgumentAmbiguityError())
            end

            function $_f_name(::MultipleArgumentAmbiguity, $(arg_names...))
                throw(MultipleArgumentAmbiguityError())
            end

            import MultipleInterfaces: var"-MultipleInterfaces-signatures-"

            let
                global var"-MultipleInterfaces-signatures-"

                signatures_ = var"-MultipleInterfaces-signatures-"($f_name)
                push!(signatures_, ($(signature...), ))


                function $(esc(Symbol("-MultipleInterfaces-signatures-")))(::typeof($f_name))
                    signatures_
                end
            end
        end

        $_f_name(::Tuple{$(interface_signature...)}, $(arg_names...)) = $(body.args...)

        import MultipleInterfaces: var"-MultipleInterfaces-interface_signatures-"

        let
            global var"-MultipleInterfaces-interface_signatures-"

            signatures_ = var"-MultipleInterfaces-interface_signatures-"($_f_name)
            updated_signatures = (signatures_..., ($(interface_objects...), ))

            function $(esc(Symbol("-MultipleInterfaces-interface_signatures-")))(::typeof($_f_name))
                updated_signatures
            end
        end

        # Function definitions return the generic function:
        $f_name
    end
end


# `implementeds::Tuple{Vararg{ConcreteInterface}}`
is_implemented(t::ConcreteInterface, implementeds) = in_t(t, implementeds)

function is_implemented(x::Intersection, implementeds)
    all_t(t -> in_t(t, implementeds), x.interfaces)
end


most_specific(xs::Tuple{Any}) = xs[1]

Base.@assume_effects :foldable function most_specific(xs::Tuple)
    xs2 = remove_superinterfaces(xs)

    if length(xs2) == 1
        xs2[1]
    else
        SingleArgumentAmbiguity()
    end
end


# TODO: Return more information for ambiguities so we can have more useful error messages.
Base.@assume_effects :foldable function dispatch(f, interface_args)
    arg_implementeds = map_t(_implements, interface_args)

    matching_signatures = filter_t(interface_signatures(f)) do signature
        all_t(is_implemented, signature, arg_implementeds)
    end

    matching_signatures === () && return NoMatchingIDispatchMethod()

    arg_dispatches = transpose_t(matching_signatures)
    arg_most_specific = map_t(most_specific, arg_dispatches)

    if in_t(SingleArgumentAmbiguity(), arg_most_specific)
        SingleArgumentAmbiguity()
    elseif in_t(arg_most_specific, matching_signatures)
        arg_most_specific
    else
        MultipleArgumentAmbiguity()
    end
end
