

tail(::Tuple{Any}) = ()

# This implementation of `tail` (which differs from `Base.tail`) was provided
# by Neven Sajko. See this Discourse post:
# https://discourse.julialang.org/t/compiler-recursion-limit/112698/8
function tail(x::Tuple{Any, Vararg{Any, N}}) where {N}
    f = let x = x
        i -> x[i + 1]
    end
    ntuple(f, Val(N))::NTuple{N, Any}
end


in_tuple(x::S, t::Tuple{T, Vararg}) where {S, T} = in_tuple(x, tail(t))
in_tuple(::T, t::Tuple{T, Vararg}) where {T} = true
in_tuple(_, t::Tuple{}) = false


# Might need `Base.@assume_effects :total` on this one, unless
# I can figure out a different way to make sure it compiles away.
delete(t::Tuple, x) = _delete(x, (), t)

Base.@assume_effects :total function _delete(
    x::S,
    left::Tuple,
    right::Tuple{T, Vararg}
) where {S, T}
    _delete(x, (left..., right[1]), tail(right))
end

_delete(::T, left::Tuple, right::Tuple{T, Vararg}) where {T} = (left..., tail(right)...)
_delete(_, left::Tuple, right::Tuple{}) = left

# TODO: Figure out if this commented function helps inference by
# returning one function call earlier.
#
# function _delete(x::S, left::Tuple, right::Tuple{T}) where {S, T}
#     (left..., right[1])
# end


function visit_interface(interface, visited::Tuple, targets::Tuple)
    if in_tuple(interface, visited)
        return visited, targets
    end

    # If `x` is not in `targets`, then `delete` just returns `targets`.
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


function is_most_specific(interface, targets::Tuple)
    visit_superinterfaces(superinterfaces(interface), (), targets) === nothing
end


struct SpecificityAmbiguity end


most_specific(xs::Tuple) = _most_specific((), xs)

Base.@assume_effects :total function _most_specific(left::Tuple, right::Tuple)
    x = right[1]
    rest = tail(right)
    if is_most_specific(x, (left..., rest...))
        x
    else
        _most_specific((left..., x), rest)
    end
end

_most_specific(::Tuple, ::Tuple{}) = SpecificityAmbiguity()
