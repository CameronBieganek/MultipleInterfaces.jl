

# Most of the functions in this file have analogs in Base Julia, but
# they typically have recursion or unrolling limits, which we cannot
# have in this package. Also, we need to be in full control of the
# implementations so that we can use `Base.@assume_effects :foldable`
# with reasonable confidence.


# This function assumes that `s` and `t` do not contain any duplicates.
intersect_t(::Tuple{}, t::Tuple) = ()

function intersect_t(s::Tuple, t::Tuple)
    s1 = s[1]
    s_tail = tail(s)

    if in_t(s1, t)
        (s1, intersect_t(s_tail, t)...)
    else
        intersect_t(s_tail, t)
    end
end


# This function assumes that `s` and `t` do not contain any duplicates.
union_t(::Tuple{}, t::Tuple) = t

function union_t(s::Tuple, t::Tuple)
    s1 = s[1]
    s_tail = tail(s)

    if in_t(s1, t)
        union_t(s_tail, t)
    else
        (s1, union_t(s_tail, t)...)
    end
end


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


# Get all elements of a tuple except for the last one.
front(::Tuple{Any}) = ()

function front(x::Tuple{Vararg{Any, N}}) where {N}
    f = let x = x
        i -> x[i]
    end
    ntuple(f, Val(N - 1))::NTuple{N - 1, Any}
end


in_t(x::S, t::Tuple{T, Vararg}) where {S, T} = in_t(x, tail(t))
in_t(::T, t::Tuple{T, Vararg}) where {T} = true
in_t(_, t::Tuple{}) = false


# NOTE: This function assumes that the elements of the input tuple are unique.
delete(::Tuple{}, x) = ()
delete(t::Tuple{T, Vararg}, ::T) where {T} = tail(t)

function delete(t::Tuple{S, Vararg}, x::T) where {S, T}
    (t[1], delete(tail(t), x)...)
end


map_t(f, ::Tuple{}) = ()

function map_t(f, t::Tuple)
    (
        f(t[1]),
        map_t(f, tail(t))...
    )
end


map_t(f, ::Tuple{}, ::Tuple{}) = ()

function map_t(f, t::Tuple, s::Tuple)
    (
        f(t[1], s[1]),
        map_t(f, tail(t), tail(s))...
    )
end


filter_t(f, ::Tuple{}) = ()

function filter_t(f, t::Tuple)
    if f(t[1])
        (t[1], filter_t(f, tail(t))...)
    else
        filter_t(f, tail(t))
    end
end


# `f` is a binary function.
all_t(f, ::Tuple{}, ::Tuple{}) = true

function all_t(f, s::Tuple, t::Tuple)
    if f(s[1], t[1])
        all_t(f, tail(s), tail(t))
    else
        false
    end
end


unique_t(::Tuple{}) = ()

function unique_t(t::Tuple)
    first = t[1]
    rest = tail(t)

    if in_t(first, rest)
        unique_t(rest)
    else
        (first, unique_t(rest)...)
    end
end


foldl_t(f, acc, ::Tuple{}) = acc
foldl_t(f, acc, t::Tuple) = foldl_t(f, f(acc, t[1]), tail(t))


# Just for completeness. I don't think we actually need this anywhere.
transpose_t(::Tuple{}) = ()

# Take an m-tuple of n-tuples and turn it into an n-tuple of m-tuples.
function transpose_t(ts::Tuple)
    init = map_t(_ -> (), ts[1])
    foldl_t(init, ts) do acc, t
        map_t(acc, t) do acc_arg, t_arg
            (acc_arg..., t_arg)
        end
    end
end


function is_subinterface(S::Type{<:ConcreteInterface}, T::Type{<:ConcreteInterface})
    _is_subinterface(S(), T())
end

const ≼ = is_subinterface
const ⋠ = !is_subinterface


_is_subinterface(::T, ::T) where {T <: ConcreteInterface} = true

function _is_subinterface(sub::ConcreteInterface, super::ConcreteInterface)
    visit_superinterfaces(_superinterfaces(sub), (), super) === Found()
end


struct Found end


function visit_superinterfaces(superinterfaces::Tuple, visited, target)
    out = visit_interface(superinterfaces[1], visited, target)

    if out === Found()
        Found()
    else
        visit_superinterfaces(tail(superinterfaces), out[1], out[2])
    end
end

visit_superinterfaces(::Tuple{}, visited, target) = visited, target


function visit_interface(interface, visited, target)
    if in_t(interface, visited)
        return visited, target
    end

    if interface === target
        return Found()
    end

    out = visit_superinterfaces(_superinterfaces(interface), visited, target)

    if out === Found()
        Found()
    else
        (out[1]..., interface), out[2]
    end
end


function remove_superinterfaces(interfaces)
    interfaces |> remove_superinterfaces_l |> remove_superinterfaces_r
end


remove_superinterfaces_l(xs::Tuple{Interface}) = xs
remove_superinterfaces_l(xs::Tuple) = _remove_superinterfaces_l((), xs)
_remove_superinterfaces_l(visited, ::Tuple{}) = visited

function _remove_superinterfaces_l(visited, not_visited::Tuple)
    x = not_visited[1]
    rest = tail(not_visited)
    non_superinterfaces = filter_t(y -> !_is_subinterface(x, y), rest)
    _remove_superinterfaces_l((visited..., x), non_superinterfaces)
end


remove_superinterfaces_r(xs::Tuple{Interface}) = xs
remove_superinterfaces_r(xs::Tuple) = _remove_superinterfaces_r((), xs)
_remove_superinterfaces_r(visited, ::Tuple{}) = visited

function _remove_superinterfaces_r(visited, not_visited::Tuple)
    x = not_visited[end]
    rest = front(not_visited)
    non_superinterfaces = filter_t(y -> !_is_subinterface(x, y), rest)
    _remove_superinterfaces_r((x, visited...), non_superinterfaces)
end
