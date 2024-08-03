

struct SpecificityAmbiguity end


struct InterfaceDispatchError{F} <: Exception
    f::F
    obj
end

function Base.showerror(io::IO, e::InterfaceDispatchError)
    msg = (
        """
        There is no unique most-specific interface among the intersection of \
        the interfaces that `$(e.f)` dispatches on and the interfaces that \
        the `$(typeof(e.obj))` type implements. This usually indicates that a \
        more specific ad hoc polymorphic method should be implemented for `$(e.f)` \
        either by the owner of `$(e.f)` or the owner(s) of the interfaces that \
        `$(e.f)` dispatches on.
        """
    )
    print(io, msg)
end


# TODO: See if I can figure out a reasonable way to avoid needing the `@declare` macro.
# Maybe I can use `@isdefined` to check if the top level method is defined.
# macro declare(func)
#     fname = func.args[1]
#     fname_str = String(fname)
#     _fname = uname(fname)
#     argname = func.args[2].args[2]

#     if func.args[2].args[3] !== :_
#         error(
#             "Use an `_` placeholder to indicate arguments that dispatch on an ",
#             "interface, like `foo(x: _)`."
#         )
#     end

#     ex = quote
#         function $fname($argname)
#             $_fname(ExtendableInterfaces.dispatch($fname, $argname), $argname)
#         end

#         function $_fname(::ExtendableInterfaces.SpecificityAmbiguity, $argname)
#             throw(InterfaceDispatchError($fname_str, $argname))
#         end

#         # An `@declare` call should return nothing.
#         nothing
#     end

#     esc(ex)
# end


argument_dispatches(f) = ()
signatures(f) = Tuple[]
is_signature_defined(f, signature) = (signature in signatures(f))


struct InterfaceArg end
struct TypeArg end


macro imethod(fdef)
    # For now assume the single-line form of function definition.
    signature_ex = fdef.args[1]
    body = fdef.args[2]
    body.head == :block || error("Syntax error.") # TODO: Is this reachable?
    fname = signature_ex.args[1]
    signature_args = signature_ex.args[2:end]

    signature_vec = map(signature_args) do ex
        if ex isa Symbol
            :Any
        elseif ex.head == :(::)
            ex.args[2]
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                :_
            else
                error("Syntax error.")
            end
        end
    end

    signature_str = "(" * join(signature_vec, ",") * ")"

    _fname = Symbol("imethod#$fname$signature_str")

    # TODO: There seems to be a lot of duplication of code here. See if I can simplify.

    symbolic_signature = map(signature_args) do ex
        if ex isa Symbol
            :Any
        elseif ex.head == :(::)
            ex.args[2]
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                :(ExtendableInterfaces.InterfaceArg)
            else
                error("Syntax error.")
            end
        end
    end

    # Remove interface annotations from arguments.
    normalized_signature = map(signature_args) do ex
        if ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                ex.args[2]
            else
                error("Syntax error.")
            end
        else
            ex
        end
    end

    interface_args = filter(signature_args) do ex
        ex.head == :call       &&
        ex.args[1] == :(:)     &&
        ex.args[2] isa Symbol  &&
        ex.args[3] isa Symbol
    end

    interface_argnames = map(ex -> ex.args[2], interface_args)

    argnames = map(signature_args) do ex
        if ex isa Symbol
            ex
        elseif ex.head == :(::)
            ex.args[1]
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                ex.args[2]
            else
                error("Syntax error.")
            end
        end
    end

    inverse_signature_vec = map(signature_args) do ex
        if ex isa Symbol
            :(ExtendableInterfaces.TypeArg)
        elseif ex.head == :(::)
            :(ExtendableInterfaces.TypeArg)
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                ex.args[3]
            else
                error("Syntax error.")
            end
        end
    end

    ex = quote
        if !is_signature_defined($fname, ($(symbolic_signature...), ))
            function $fname($(normalized_signature...))
                $_fname(
                    ExtendableInterfaces.dispatch($fname, $(interface_argnames...)),
                    $(argnames...)
                )
            end
            function $_fname(::ExtendableInterfaces.SpecificityAmbiguity, $(argnames...))
                throw(InterfaceDispatchError($fname, nothing))
            end
        end
        $_fname(::Tuple{$(inverse_signature_vec...)}, $(argnames...)) = $(body.args...)

        # argument_dispatches()
        let
            dispatches = ExtendableInterfaces.argument_dispatches($fname)
            updated_dispatches = update_argument_dispatches(dispatches, qqqq)
            ExtendableInterfaces.argument_dispatches(::typeof($fname)) = updated_dispatches
        end

        # signatures()
        let
            signatures = ExtendableInterfaces.signatures($fname)
            push!(signatures, $inverse_signature_vec)
            function ExtendableInterfaces.signatures(::typeof($fname))
                (signatures..., $interface())
            end
        end

        # Function definitions return the generic function:
        $fname
    end

    esc(ex)
end


function visit_interface(interface, visited::Tuple, targets::Tuple)
    if in_tuple(interface, visited)
        return visited, targets
    end

    # If `interface` is not in `targets`, then `delete` just returns `targets`.
    targets2 = delete(targets, interface)
    targets2 === () && return nothing

    out = visit_superinterfaces(superinterfaces(interface), visited, targets2)
    out === nothing && return nothing

    (out[1]..., interface), out[2]
end

function visit_superinterfaces(superinterfaces::Tuple, visited::Tuple, targets::Tuple)
    out = visit_interface(superinterfaces[1], visited, targets)
    out === nothing && return nothing
    visit_superinterfaces(tail(superinterfaces), out[1], out[2])
end

visit_superinterfaces(::Tuple{}, visited::Tuple, targets::Tuple) = visited, targets


function is_subinterface_all(interface, targets::Tuple)
    visit_superinterfaces(superinterfaces(interface), (), targets) === nothing
end

# TODO:
# most_specific(xs::Tuple{}) = PolymorphicMethodError("No polymorphic method matching foo(x: A)")

most_specific(xs::Tuple{Any}) = xs[1]
most_specific(xs::Tuple) = _most_specific((), xs)

Base.@assume_effects :foldable function _most_specific(left::Tuple, right::Tuple)
    x = right[1]
    rest = tail(right)
    if is_subinterface_all(x, (left..., rest...))
        x
    else
        _most_specific((left..., x), rest)
    end
end

_most_specific(::Tuple, ::Tuple{}) = SpecificityAmbiguity()


function dispatch(f, x)
    most_specific(tuple_intersect(imethods(f), implements(x)))
end
