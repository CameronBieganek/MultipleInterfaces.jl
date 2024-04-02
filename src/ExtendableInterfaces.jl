
module ExtendableInterfaces

export @interface, requiredmethods, superinterfaces

function requiredmethods end
function superinterfaces end

function interface_helper(name, superinterfaces, methods)
    superinterfaces = Expr(:tuple, map(s -> :($s()), superinterfaces.args)...)

    # No error handling yet. For now we assume that `methods` is
    # a block with a list of function names (Symbols).
    methods = filter(arg -> arg isa Symbol, methods.args)

    name_str = String(name)

    ex = quote
        struct $name
            methods::Tuple
            $name() = new(tuple($(methods...)))
        end

        ExtendableInterfaces.superinterfaces(::$name) = $superinterfaces
        ExtendableInterfaces.requiredmethods(I::$name) = I.methods

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

end
