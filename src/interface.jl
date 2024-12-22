

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

        struct $name <: Interface end

        ExtendableInterfaces.superinterfaces(::$name) = $superinterface_objs
        ExtendableInterfaces.required_methods(::$name) = ($(methods...),)
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


# TODO: Enforce that every interface contain at least one required method.
# I.e., not just root interfaces.
function throw_at_least_one_method_error()
    throw(ArgumentError(
        "An interface that does not extend any other interface must require " *
        "at least one method."
    ))
end


# TODO:
# - Add an `Intersection` type and overload `+(a::Interface, b::Interface)` so that
#   it is equivalent to `Intersection{a, b}`.
# - Require any interface that extends other interfaces to include at least one required method.
#     - The first bullet point makes it easy to add an alias for an intersection type.


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


implements(::Type{T}) where {T} = ()
implements(::T) where {T} = implements(T)


function throw_type_macro_syntax_error()
    throw(ArgumentError(
        "Syntax error in `@type`. To declare that type `Foo` implements interfaces" *
        "`A` and `B`, write `@type implements A, B`."
    ))
end


# This function is not part of the dispatch machinery, so it does not need to compile away.
# This function returns all (possibly transitive) superinterfaces of
# `interface`, including `interface`.
function ancestors(interface::Interface)
    visited = ()
    stack = Interface[interface]

    while !isempty(stack)
        interface = pop!(stack)
        if !in_t(interface, visited)
            visited = (visited..., interface)
            for superinterface in superinterfaces(interface)
                push!(stack, superinterface)
            end
        end
    end

    visited
end


function update_implemented(::Type{T}, new_impls::Tuple) where {T}
    foldl(new_impls; init=implements(T)) do implemented, new_impl
        union_t(implemented, ancestors(new_impl))
    end
end


macro type(type, implements::Symbol, interfaces_ex)
    type = esc(type)

    implements != :implements && throw_type_macro_syntax_error()

    if interfaces_ex isa Symbol
        interface_syms = [interfaces_ex]
    else
        interfaces_ex.head != :tuple && throw_type_macro_syntax_error()
        interface_syms = interfaces_ex.args
    end

    interfaces = map(sym -> :($(esc(sym))()), interface_syms)

    quote
        let
            implemented = update_implemented($type, ($(interfaces...), ))
            ExtendableInterfaces.implements(::Type{$type}) = implemented
        end
    end
end
