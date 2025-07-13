

struct NoMatchingIDispatchMethod end
struct SingleArgumentAmbiguity end
struct MultipleArgumentAmbiguity end


struct NoMatchingIDispatchMethodError <: Exception end
struct SingleArgumentAmbiguityError <: Exception end
struct MultipleArgumentAmbiguityError <: Exception end


# TODO: Improve the error messages.

function Base.showerror(io::IO, ::NoMatchingIDispatchMethodError)
    print(io, "No matching i-dispatch method.")
end

function Base.showerror(io::IO, ::SingleArgumentAmbiguityError)
    print(io, "There is a single argument i-dispatch ambiguity.")
end

function Base.showerror(io::IO, ::MultipleArgumentAmbiguityError)
    print(io, "There is a multiple argument i-dispatch ambiguity.")
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
struct TypeArg end


sym_vec(n) = Vector{Symbol}(undef, n)
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


# TODO: Fix handling of first argument in `foo(::Int, a: A)`.
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
    # ...given the input `foo(x::Int, a: A, y::String, b: B)`
    #
    # signature:                 [:Int, :InterfaceArg, :String, :InterfaceArg]
    # underscore_signature:      [:Int, :_, :String, :_]
    # underscore_signature_str:  "(Int,_,String,_)"
    # normalized_signature_ex:   [:(x::Int), :a, :(y::String), :b]
    # arg_names:                 [:x, :a, :y, :b]
    # interface_signature:       [esc(:A), esc(:B)]
    # interface_arg_names:       [:a, :b]
    # interface_objects:         [:($(esc(:A)())), :($(esc(:B)()))]

    signature = sym_vec(n_args)
    underscore_signature = sym_vec(n_args)
    arg_names = sym_vec(n_args)
    normalized_signature_ex = Vector{Any}(undef, n_args)

    interface_arg_names = Symbol[]
    interface_signature = Expr[]   # Escaped symbols.
    interface_objects   = Expr[]

    for (i, arg_ex) in enumerate(signature_ex)
        if arg_ex isa Symbol
            name = normalized_arg = arg_ex
            type = underscore_type = :Any
        elseif arg_ex.head == :(::)
            name = arg_ex.args[1]
            type = underscore_type = arg_ex.args[2]
            normalized_arg = arg_ex
        elseif arg_ex.head == :call
            if (
                arg_ex.args[1] == :(:) &&
                arg_ex.args[2] isa Symbol
            )
                type = :InterfaceArg
                underscore_type = :_
                name = normalized_arg = arg_ex.args[2]
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
        arg_names[i] = name
        normalized_signature_ex[i] = normalized_arg
    end

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
