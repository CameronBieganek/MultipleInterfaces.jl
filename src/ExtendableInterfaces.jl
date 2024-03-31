
module ExtendableInterfaces

export @interface, requiredmethods, superinterfaces

function requiredmethods end
function superinterfaces end

macro interface(name, methods)
    # No error handling yet. For now we assume that `methods` is
    # a block with a list of function names (Symbols).
    methods = filter(arg -> arg isa Symbol, methods.args)

    ex = quote
        struct $name
            methods::Tuple
            $name() = new(tuple($(methods...)))
        end
        ExtendableInterfaces.superinterfaces(::$name) = ()
        ExtendableInterfaces.requiredmethods(I::$name) = I.methods
    end

    esc(ex)
end

end
