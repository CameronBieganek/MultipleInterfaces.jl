

struct SpecificityAmbiguity end


struct InterfaceDispatchError <: Exception
    fname::String
    obj
end

function Base.showerror(io::IO, e::InterfaceDispatchError)
    msg = (
        """
        There is no unique most-specific interface among the intersection of \
        the interfaces that `$(e.fname)` dispatches on and the interfaces that \
        the `$(typeof(e.obj))` type implements. This usually indicates that a \
        more specific ad hoc polymorphic method should be implemented for `$(e.fname)` \
        either by the owner of `$(e.fname)` or the owner(s) of the interfaces that \
        `$(e.fname)` dispatches on.
        """
    )
    print(io, msg)
end


uname(name::Symbol) = Symbol(string("_", name))


# TODO: See if I can figure out a reasonable way to avoid needing the `@declare` macro.
# Maybe I can use `@isdefined` to check if the top level method is defined.
macro declare(func)
    fname = func.args[1]
    fname_str = String(fname)
    _fname = uname(fname)
    argname = func.args[2].args[2]

    if func.args[2].args[3] !== :_
        error(
            "Use an `_` placeholder to indicate arguments that dispatch on an ",
            "interface, like `foo(x: _)`."
        )
    end

    ex = quote
        function $fname($argname)
            $_fname(ExtendableInterfaces.dispatch($fname, $argname), $argname)
        end

        function $_fname(::ExtendableInterfaces.SpecificityAmbiguity, $argname)
            throw(InterfaceDispatchError($fname_str, $argname))
        end

        # An `@declare` call should return nothing.
        nothing
    end

    esc(ex)
end


adhoc_methods(::Any) = ()


macro adhoc(fdef)
    # For now assume the single-line form of function definition.
    signature = fdef.args[1]
    body = fdef.args[2]
    colon = signature.args[2]

    fname = signature.args[1]
    _fname = uname(fname)

    argname = colon.args[2]
    interface = colon.args[3]

    ex = quote
        if @isdefined $fname
            # It's important to have this before the `let` block, so that if the interface
            # is undefined we get an `UndefVarError` before the `let` block is run. Otherwise
            # a user could call this macro and get an error, but the `let` block has already
            # updated `adhoc_methods`.
            $_fname(::$interface, $argname) = $(body.args...)

            let
                signatures = ExtendableInterfaces.adhoc_methods($fname)

                function ExtendableInterfaces.adhoc_methods(::typeof($fname))
                    (signatures..., $interface())
                end
            end

            # Function definitions return the generic function:
            $fname
        else
            error(
                "Ad hoc polymorphic functions must be declared with `@declare` before ",
                "methods are declared with `@adhoc`."
            )
        end
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
    most_specific(tuple_intersect(adhoc_methods(f), implements(x)))
end
