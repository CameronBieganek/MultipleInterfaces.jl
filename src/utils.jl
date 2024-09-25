

# This function assumes that `s` and `t` do not contain any duplicates.
tintersect(s::Tuple, t::Tuple) = _tintersect((), s, t)

Base.@assume_effects :foldable function _tintersect(out::Tuple, s::Tuple, t::Tuple)
    s1 = s[1]
    s_tail = tail(s)
    if in_tuple(s1, t)
        _tintersect((out..., s1), s_tail, t)
    else
        _tintersect(out, s_tail, t)
    end
end

_tintersect(out::Tuple, ::Tuple{}, ::Tuple) = out


# This function assumes that `s` and `t` do not contain any duplicates.
tunion(s::Tuple, t::Tuple) = _tunion(s, s, t)

Base.@assume_effects :foldable function _tunion(out::Tuple, s::Tuple, t::Tuple)
    t1 = t[1]
    t_tail = tail(t)
    if in_tuple(t1, s)
        _tunion(out, s, t_tail)
    else
        _tunion((out..., t1), s, t_tail)
    end
end

_tunion(out::Tuple, ::Tuple, ::Tuple{}) = out


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
        if !in_tuple(interface, visited)
            visited = (visited..., interface)
            for superinterface in superinterfaces(interface)
                push!(stack, superinterface)
            end
        end
    end

    visited
end


tmap(f, ::Tuple{}, ::Tuple{}) = ()

function tmap(f, t::Tuple, s::Tuple)
    (
        f(t[1], s[1]),
        tmap(f, tail(t), tail(s))...
    )
end
