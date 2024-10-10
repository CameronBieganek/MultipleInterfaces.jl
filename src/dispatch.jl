

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
    print(io, "There is a single argument dispatch ambiguity.")
end

function Base.showerror(io::IO, ::MultipleArgumentAmbiguityError)
    print(io, "There is a multiple argument dispatch ambiguity.")
end


signatures(f) = Tuple[]
is_signature_defined(f, signature) = (signature in signatures(f))


# `interface_args_dispatches` returns a separate tuple for each argument, whereas
# `interface_signatures` returns a tuple of signature tuples, where each signature
# tuple indicates the interfaces that are dispatched on for one i-dispatch method.
interface_args_dispatches(f) = ()
interface_signatures(f) = ()


struct InterfaceArg end
struct TypeArg end


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


macro idispatch(fdef)
    # For now assume the single-line form of function definition.
    signature_ex = fdef.args[1]
    body = fdef.args[2]
    body.head == :block || error("Syntax error.") # TODO: Is this reachable?
    fname = signature_ex.args[1]
    efname = esc(fname)
    signature_args = signature_ex.args[2:end]

    signature_vec = map(signature_args) do ex
        if ex isa Symbol
            :Any
        elseif ex.head == :(::)
            ex.args[end]
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                :_
            else
                error("Syntax error.")
            end
        end
    end

    signature_str = "(" * join(signature_vec, ",") * ")"

    _fname = esc(Symbol("idispatch#$fname$signature_str"))

    # TODO: There seems to be a lot of duplication of code here. See if I can simplify.
    # I should probably just use a single for loop to build up most of the vectors.

    symbolic_signature = map(signature_args) do ex
        if ex isa Symbol
            :Any
        elseif ex.head == :(::)
            ex.args[end]
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                :InterfaceArg
            else
                error("Syntax error.")
            end
        end
    end

    # Remove interface annotations from arguments.
    normalized_signature = map(signature_args) do ex
        if ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                ex.args[2]
            else
                error("Syntax error.")
            end
        else
            ex
        end
    end

    interface_args = filter(signature_args) do ex
        ex.head == :call       &&
        ex.args[1] == :(:)     &&
        ex.args[2] isa Symbol  &&
        ex.args[3] isa Symbol
    end

    interface_argnames = map(ex -> ex.args[2], interface_args)
    interface_args_interface_types = map(ex -> esc(ex.args[3]), interface_args)
    interface_args_interface_objs = map(ex -> :($(esc(ex.args[3]))()), interface_args)

    argnames = map(signature_args) do ex
        if ex isa Symbol
            ex
        elseif ex.head == :(::)
            ex.args[1]
        elseif ex.head == :call
            if ex.args[1] == :(:) && ex.args[2] isa Symbol && ex.args[3] isa Symbol
                ex.args[2]
            else
                error("Syntax error.")
            end
        end
    end

    quote
        if (
            !isdefined(@__MODULE__, $(QuoteNode(fname))) ||
            !is_signature_defined($efname, ($(symbolic_signature...), ))
        )
            function $efname($(normalized_signature...))
                dispatch_to = dispatch($_fname, ($(interface_argnames...), ))
                $_fname(dispatch_to, $(argnames...))
            end

            function $_fname(::NoMatchingIDispatchMethod, $(argnames...))
                throw(NoMatchingIDispatchMethodError())
            end

            function $_fname(::SingleArgumentAmbiguity, $(argnames...))
                throw(SingleArgumentAmbiguityError())
            end

            function $_fname(::MultipleArgumentAmbiguity, $(argnames...))
                throw(MultipleArgumentAmbiguityError())
            end

            let
                signatures_ = ExtendableInterfaces.signatures($efname)
                push!(signatures_, ($(symbolic_signature...), ))
                ExtendableInterfaces.signatures(::typeof($efname)) = signatures_
            end
        end
        $_fname(::Tuple{$(interface_args_interface_types...)}, $(argnames...)) = $(body.args...)

        let
            dispatches = ExtendableInterfaces.interface_args_dispatches($_fname)
            updated_dispatches = update_interface_dispatches(
                dispatches,
                ($(interface_args_interface_objs...), )
            )
            ExtendableInterfaces.interface_args_dispatches(::typeof($_fname)) = updated_dispatches
        end

        let
            signatures_ = ExtendableInterfaces.interface_signatures($_fname)
            updated_signatures = (signatures_..., ($(interface_args_interface_objs...), ))
            ExtendableInterfaces.interface_signatures(::typeof($_fname)) = updated_signatures
        end

        # Function definitions return the generic function:
        $efname
    end
end


function visit_interface(interface, visited::Tuple, targets::Tuple)
    if in_t(interface, visited)
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


most_specific(xs::Tuple{Any}) = xs[1]
most_specific(xs::Tuple) = _most_specific((), xs)

# TODO: Can I simplify this recursion too?
# Maybe use `any_t` (which I haven't written yet).
Base.@assume_effects :foldable function _most_specific(left::Tuple, right::Tuple)
    x = right[1]
    rest = tail(right)
    if is_subinterface_all(x, (left..., rest...))
        x
    else
        _most_specific((left..., x), rest)
    end
end

_most_specific(::Tuple, ::Tuple{}) = SingleArgumentAmbiguity()


function dispatch(f, interface_args)
    argwise_implemented = map_t(implements, interface_args)

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
