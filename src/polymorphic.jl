

struct SpecificityAmbiguity end


function _polymorphic_methods end
uname(name::Symbol) = Symbol(string("_", name))


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

        ExtendableInterfaces._polymorphic_methods(::typeof($fname)) = ()

        # An `@declare` call should return nothing.
        nothing
    end

    esc(ex)
end


struct InterfaceDispatchError <: Exception
    fname::String
    obj
end

function Base.showerror(io::IO, e::InterfaceDispatchError)
    msg = (
        """
        There is no unique most-specific interface among the intersection of \
        the interfaces that $(e.fname) dispatches on and the interfaces that \
        the `$(typeof(e.obj))` type implements. This usually indicates that a \
        more specific adhoc-polymorphic method should be implemented for $(e.fname) \
        either by the owner of $(e.fname) or the owner(s) of the interfaces that \
        $(e.fname) dispatches on.
        """
    )
    print(io, msg)
end


macro polymorphic(fdef)
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
            # updated `_polymorphic_methods`.
            $_fname(::$interface, $argname) = $(body.args...)

            let
                signatures = ExtendableInterfaces._polymorphic_methods($fname)

                function ExtendableInterfaces._polymorphic_methods(::typeof($fname))
                    (signatures..., $interface())
                end
            end

            # Function definitions return the generic function:
            $fname
        else
            error(
                "Polymorphic functions must be declared with `@declare` before ",
                "methods are declared with `@polymorphic`."
            )
        end
    end

    esc(ex)
end
