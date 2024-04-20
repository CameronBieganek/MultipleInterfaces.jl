

function required_methods end
function superinterfaces end


function interface_helper(name, superinterfaces, methods_block)
    if isnothing(methods_block)
        methods = ()
    else
        check_methods_block_head(methods_block)

        if any(arg -> !(arg isa Union{Symbol, LineNumberNode}), methods_block.args)
            throw(ArgumentError(
                "Something other than a function name has been provided in the " *
                "list of required methods for an interface."
            ))
        end

        methods = filter(arg -> arg isa Symbol, methods_block.args)
    end

    superinterface_objs = Expr(:tuple, map(s -> :($s()), superinterfaces.args)...)

    name_str = String(name)

    ex = quote
        # This will throw an `UndefVarErr` if any of the declared superinterfaces
        # are not yet defined.
        $(superinterfaces.args...)

        # Ditto for the declared methods of the interface.
        $(methods...)

        struct $name end

        ExtendableInterfaces.superinterfaces(::$name) = $superinterface_objs
        ExtendableInterfaces.required_methods(::$name) = ($(methods...),)

        Base.show(io::IO, ::$name) = print(io, $name_str, "()")
        Base.show(io::IO, ::MIME"text/plain", ::$name) = print(io, "Interface: ", $name_str)
    end

    esc(ex)
end


function check_methods_block_head(methods_block)
    if methods_block.head != :block
        throw(ArgumentError(
            "The required methods for an interface must be listed in a `begin` block."
        ))
    end
end


function throw_at_least_one_method_error()
    throw(ArgumentError(
        "An interface that does not extend any other interface must require " *
        "at least one method."
    ))
end


# We could just leave this undefined and thus get a method error, but macro
# method errors are usually not very informative.
macro interface(name::Symbol)
    throw_at_least_one_method_error()
end


macro interface(name::Symbol, methods_block::Expr)
    check_methods_block_head(methods_block)
    length(methods_block.args) < 2 && throw_at_least_one_method_error()
    interface_helper(name, :(()), methods_block)
end


macro interface(
    name::Symbol,
    extends::Symbol,
    superinterfaces::Union{Symbol, Expr},
    methods_block=nothing
)
    if extends !== :extends
        throw(ArgumentError(
            "Use `extends` syntax to make a subinterface, like `@interface C extends A, B`."
        ))
    end

    if superinterfaces isa Symbol
        superinterfaces = :(($superinterfaces, ))
    else
        if (
            superinterfaces.head != :tuple  ||
            any(arg -> !(arg isa Symbol), superinterfaces.args)
        )
            throw(ArgumentError(
                "The superinterfaces must be provided as a comma-separated list, like " *
                "`@interface C extends A, B`."
            ))
        end
    end

    interface_helper(name, superinterfaces, methods_block)
end
