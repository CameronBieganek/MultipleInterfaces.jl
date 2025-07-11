

# This function gets overloaded by the `@interface` macro in the user scope.
function var"-ExtendableInterfaces-superinterfaces-" end

# A more convenient name for internal usage.
_superinterfaces(x::ConcreteInterface) = var"-ExtendableInterfaces-superinterfaces-"(x)

# The exported version that dispatches on interface types rather than instances.
function superinterfaces(I::Type{<:ConcreteInterface})
    map(typeof, var"-ExtendableInterfaces-superinterfaces-"(I()))
end


# This function gets overloaded by the `@interface` macro in the user scope.
function var"-ExtendableInterfaces-required_methods-" end

# The exported version that dispatches on interface types rather than instances.
function required_methods(I::Type{<:ConcreteInterface})
    var"-ExtendableInterfaces-required_methods-"(I())
end


# This function gets overloaded by the `@interface` macro in the user scope.
function var"-ExtendableInterfaces-concrete_interface_id-" end

# A more convenient name for internal usage.
concrete_interface_id(x::ConcreteInterface) = var"-ExtendableInterfaces-concrete_interface_id-"(x)


function interface_helper(name, superinterfaces, methods_block)
    if isnothing(methods_block)
        methods = ()
    else
        check_methods_block_head(methods_block)

        if any(arg -> !(arg isa LineNumberNode) && !is_name(arg), methods_block.args)
            throw(ArgumentError(
                "Something other than a function name has been provided in the " *
                "list of required methods for an interface."
            ))
        end

        methods = filter(is_name, methods_block.args)
        methods = map(esc, methods)
    end

    esc_superinterfaces = map(esc, superinterfaces.args)
    esc_superinterface_objs = map(s -> :($s()), esc_superinterfaces)
    tuple_esc_superinterface_objs = Expr(:tuple, esc_superinterface_objs...)

    esc_name = esc(name)

    quote
        # This will throw an `UndefVarErr` if any of the declared superinterfaces
        # are not yet defined.
        $(esc_superinterfaces...)

        # Ditto for the declared methods of the interface.
        $(methods...)

        struct $esc_name <: ConcreteInterface end

        import ExtendableInterfaces: var"-ExtendableInterfaces-superinterfaces-"
        import ExtendableInterfaces: var"-ExtendableInterfaces-required_methods-"
        import ExtendableInterfaces: var"-ExtendableInterfaces-concrete_interface_id-"

        function $(esc(Symbol("-ExtendableInterfaces-superinterfaces-")))(::$esc_name)
            $tuple_esc_superinterface_objs
        end

        function $(esc(Symbol("-ExtendableInterfaces-required_methods-")))(::$esc_name)
            ($(methods...),)
        end

        let
            global var"-ExtendableInterfaces-concrete_interface_id-"

            id = UInt128(uuid4())

            function $(esc(Symbol("-ExtendableInterfaces-concrete_interface_id-")))(::$esc_name)
                id
            end
        end

        nothing
    end
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

    if is_name(superinterfaces)
        superinterfaces = :(($superinterfaces, ))
    else
        if superinterfaces.head != :tuple || any(!is_name, superinterfaces.args)
            throw(ArgumentError(
                "The superinterfaces must be provided as a comma-separated list, like " *
                "`@interface C extends A, B`."
            ))
        end
    end

    interface_helper(name, superinterfaces, methods_block)
end


# This function gets overloaded by the `@type` macro in the user scope.
var"-ExtendableInterfaces-implements-"(::Type) = ()

# A more convenient name for internal usage.
_implements(T::Type) = var"-ExtendableInterfaces-implements-"(T)
_implements(::T) where {T} = _implements(T)

# The exported version. Returns interface types rather than instances.
implements(T::Type) = map(typeof, _implements(T))


function throw_type_macro_syntax_error()
    throw(ArgumentError(
        "Syntax error in `@type`. To declare that type `Foo` implements interfaces" *
        "`A` and `B`, write `@type Foo implements A, B`."
    ))
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


function update_implemented(::Type{T}, new_impls::Tuple) where {T}
    foldl(new_impls; init=_implements(T)) do implemented, new_impl
        union_t(implemented, ancestors(new_impl))
    end
end


# TODO: Handle parametric types and possibly abstract types. Or maybe error
# if `isabstracttype(T)` is true. (That's only true if it is an abstract type
# declared with `abstract type`.)
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
        import ExtendableInterfaces: var"-ExtendableInterfaces-implements-"

        let
            global var"-ExtendableInterfaces-implements-"

            implemented = update_implemented($type, ($(esc_interface_objs...), ))

            function $(esc(Symbol("-ExtendableInterfaces-implements-")))(::Type{$type})
                implemented
            end
        end

        nothing
    end
end
