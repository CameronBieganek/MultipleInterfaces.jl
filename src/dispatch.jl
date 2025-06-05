

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


# TODO: Make `signatures` and `interface_signatures` hidden.
# TODO: Add unit tests to make sure everything works when `ExtendableInterfaces` is
# not in scope. I.e., when the user does this:
# `using ExtendableInterfaces: @interface, @type, @idispatch`.


signatures(f) = Tuple[]
is_signature_defined(f, signature) = (signature in signatures(f))


# Return a tuple of signature tuples, where each signature tuple indicates the
# interfaces that are dispatched on for one i-dispatch method.
interface_signatures(f) = ()


struct InterfaceArg end
struct TypeArg end


# TODO: Delete these.
function update_interface_dispatches(::Tuple{}, interface_args_interfaces::Tuple)
    map(i -> (i, ), interface_args_interfaces)
end


function update_interface_dispatches(dispatches::Tuple, interface_args_interfaces::Tuple)
    map(dispatches, interface_args_interfaces) do arg_dispaches, interface
        if in_t(interface, arg_dispaches)
            arg_dispaches
        else
            (arg_dispaches..., interface)
        end
    end
end


sym_vec(n) = Vector{Symbol}(undef, n)
throw_idispatch_syntax_error() = error("Syntax error in the `@idispatch` macro.")


function is_AND_ex(ex)
    ex isa Expr &&
    ex.head == :call &&
    ex.args[1] == :&
end


function _concrete_interfaces(ex)
    ex isa Symbol && return ex
    is_AND_ex(ex) || throw_idispatch_syntax_error()
    vcat(_concrete_interfaces(ex.args[2]), _concrete_interfaces(ex.args[3]))
end

concrete_interfaces(ex) = esc.(_concrete_interfaces(ex))


# TODO: Fix handling of first argument in `foo(::Int, a: A)`.
macro idispatch(fdef)
    # For now assume the single-line form of function definition.
    call_ex = fdef.args[1]
    body = fdef.args[2]
    body.head == :block || error("Syntax error.") # TODO: Is this reachable?
    f_name_sym = call_ex.args[1]
    f_name = esc(f_name_sym)
    signature_ex = call_ex.args[2:end]
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
            type = underscore_type = arg_ex.args[end]
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
                if interface_ex isa Symbol
                    push!(interface_signature, esc(interface_ex))
                    push!(interface_objects, :($(esc(interface_ex))()))
                elseif is_AND_ex(interface_ex)
                    arg_signature = :(Intersection{Tuple{$(concrete_interfaces(interface_ex)...)}})
                    push!(interface_signature, arg_signature)
                    push!(interface_objects, :($(esc(interface_ex))))
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
    _f_name = esc(Symbol("idispatch#$f_name_sym$underscore_signature_str"))

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

            let
                signatures_ = ExtendableInterfaces.signatures($f_name)
                push!(signatures_, ($(signature...), ))
                ExtendableInterfaces.signatures(::typeof($f_name)) = signatures_
            end
        end
        $_f_name(::Tuple{$(interface_signature...)}, $(arg_names...)) = $(body.args...)

        let
            signatures_ = ExtendableInterfaces.interface_signatures($_f_name)
            updated_signatures = (signatures_..., ($(interface_objects...), ))
            ExtendableInterfaces.interface_signatures(::typeof($_f_name)) = updated_signatures
        end

        # Function definitions return the generic function:
        $f_name
    end
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


Base.@assume_effects :foldable function dispatch(f, interface_args)
    argwise_implemented = map_t(_implements, interface_args)

    matching_signatures = filter_t(interface_signatures(f)) do signature
        all_t(in_t, signature, argwise_implemented)
    end

    matching_signatures === () && return NoMatchingIDispatchMethod()

    argwise_most_specific = map_t(transpose_t(matching_signatures)) do dispatches
        most_specific(unique_t(dispatches))
    end

    # TODO: Return more information for ambiguities so we can have more useful error messages.
    if in_t(SingleArgumentAmbiguity(), argwise_most_specific)
        SingleArgumentAmbiguity()
    elseif in_t(argwise_most_specific, matching_signatures)
        argwise_most_specific
    else
        MultipleArgumentAmbiguity()
    end
end
