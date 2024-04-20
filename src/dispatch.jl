

# Define the arrows to point from subinterfaces to superinterfaces.
children(interface) = superinterfaces(interface)


tail(x::Tuple{Any}) = ()

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
Base.@assume_effects :total delete(t::Tuple, x) = _delete(x, (), t)

# function _delete(x::S, left::Tuple, right::Tuple{T}) where {S, T}
#     (left..., right[1])
# end

function _delete(x::S, left::Tuple, right::Tuple{T, Vararg}) where {S, T}
    _delete(x, (left..., right[1]), tail(right))
end

_delete(::T, left::Tuple, right::Tuple{T, Vararg}) where {T} = (left..., tail(right)...)
_delete(_, left::Tuple, right::Tuple{}) = left


function visit_first_node(x, targets::Tuple)
    visit_children(children(x), (), targets)
end


function is_minimum(x, targets::Tuple)
    visit_children(children(x), (), targets) === nothing
end


function visit_node(x, visited::Tuple, targets::Tuple)
    if in_tuple(x, visited)
        return visited, targets
    end

    # If `x` is not in `targets`, then `delete` just returns `targets`.
    targets2 = delete(targets, x)
    targets2 === () && return nothing

    out = visit_children(children(x), visited, targets2)
    out === nothing && return nothing

    (out[1]..., x), out[2]
end

function visit_children(children::Tuple, visited::Tuple, targets::Tuple)
    out = visit_node(children[1], visited, targets)
    out === nothing && return nothing
    visit_children(tail(children), out[1], out[2])
end

visit_children(children::Tuple{}, visited::Tuple, targets::Tuple) = visited, targets


struct NoUniqueMinimum end


find_minimum(xs::Tuple) = _find_minimum((), xs)

Base.@assume_effects :total function _find_minimum(left::Tuple, right::Tuple)
    x = right[1]
    rest = tail(right)
    if is_minimum(x, (left..., rest...))
        x
    else
        _find_minimum((left..., x), rest)
    end
end

_find_minimum(left::Tuple, right::Tuple{}) = NoUniqueMinimum()
