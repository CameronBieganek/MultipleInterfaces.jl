

# This function assumes that `s` and `t` do not contain any duplicates.
intersect_t(s::Tuple, t::Tuple) = _intersect_t((), s, t)

Base.@assume_effects :foldable function _intersect_t(out::Tuple, s::Tuple, t::Tuple)
    s1 = s[1]
    s_tail = tail(s)
    if in_t(s1, t)
        _intersect_t((out..., s1), s_tail, t)
    else
        _intersect_t(out, s_tail, t)
    end
end

_intersect_t(out::Tuple, ::Tuple{}, ::Tuple) = out


# This function assumes that `s` and `t` do not contain any duplicates.
union_t(s::Tuple, t::Tuple) = _union_t(s, s, t)

Base.@assume_effects :foldable function _union_t(out::Tuple, s::Tuple, t::Tuple)
    t1 = t[1]
    t_tail = tail(t)
    if in_t(t1, s)
        _union_t(out, s, t_tail)
    else
        _union_t((out..., t1), s, t_tail)
    end
end

_union_t(out::Tuple, ::Tuple, ::Tuple{}) = out


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


in_t(x::S, t::Tuple{T, Vararg}) where {S, T} = in_t(x, tail(t))
in_t(::T, t::Tuple{T, Vararg}) where {T} = true
in_t(_, t::Tuple{}) = false


delete(t::Tuple, x) = _delete(x, (), t)

Base.@assume_effects :foldable function _delete(
    x::S,
    left::Tuple,
    right::Tuple{T, Vararg}
) where {S, T}
    _delete(x, (left..., right[1]), tail(right))
end

_delete(::T, left::Tuple, right::Tuple{T, Vararg}) where {T} = (left..., tail(right)...)
_delete(_, left::Tuple, right::Tuple{}) = left


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


map_t(f, ::Tuple{}, ::Tuple{}) = ()

function map_t(f, t::Tuple, s::Tuple)
    (
        f(t[1], s[1]),
        map_t(f, tail(t), tail(s))...
    )
end
