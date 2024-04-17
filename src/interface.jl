

function requiredmethods end
function superinterfaces end


function interface_helper(name, superinterfaces, methods)
    superinterface_objs = Expr(:tuple, map(s -> :($s()), superinterfaces.args)...)

    # No error handling yet. For now we assume that `methods` is
    # a block with a list of function names (Symbols).
    methods = filter(arg -> arg isa Symbol, methods.args)

    name_str = String(name)

    ex = quote
        # This will throw an `UndefVarErr` if any of the declared superinterfaces
        # are not yet defined.
        $(superinterfaces.args...)

        # Ditto for the declared methods of the interface.
        $(methods...)

        struct $name end

        ExtendableInterfaces.superinterfaces(::$name) = $superinterface_objs
        ExtendableInterfaces.requiredmethods(::$name) = ($(methods...),)

        Base.show(io::IO, ::$name) = print(io, $name_str, "()")
        Base.show(io::IO, ::MIME"text/plain", ::$name) = print(io, "Interface: ", $name_str)
    end

    esc(ex)
end


macro interface(name::Symbol, methods)
    interface_helper(name, :(()), methods)
end


macro interface(name::Symbol, extends::Symbol, superinterfaces, methods)
    extends === :extends || error("Invalid interface extension syntax.")

    if superinterfaces isa Symbol
        superinterfaces = :(($superinterfaces, ))
    end

    interface_helper(name, superinterfaces, methods)
end
