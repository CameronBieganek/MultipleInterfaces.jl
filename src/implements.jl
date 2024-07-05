

abstract type Interface end


# This function assumes that `s` and `t` do not contain any duplicates.
tuple_intersect(s::Tuple, t::Tuple) = _tuple_intersect((), s, t)

Base.@assume_effects :foldable function _tuple_intersect(out::Tuple, s::Tuple, t::Tuple)
    s1 = s[1]
    s_tail = tail(s)
    if in_tuple(s1, t)
        _tuple_intersect((out..., s1), s_tail, t)
    else
        _tuple_intersect(out, s_tail, t)
    end
end

_tuple_intersect(out::Tuple, ::Tuple{}, ::Tuple) = out


# This function assumes that `s` and `t` do not contain any duplicates.
tuple_union(s::Tuple, t::Tuple) = _tuple_union(s, s, t)

Base.@assume_effects :foldable function _tuple_union(out::Tuple, s::Tuple, t::Tuple)
    t1 = t[1]
    t_tail = tail(t)
    if in_tuple(t1, s)
        _tuple_union(out, s, t_tail)
    else
        _tuple_union((out..., t1), s, t_tail)
    end
end

_tuple_union(out::Tuple, ::Tuple, ::Tuple{}) = out


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


implements(::Type{T}) where {T} = ()
implements(::T) where {T} = implements(T)


# TODO: Change this to this:
# @type Foo implements A, B
macro implements(ex)
    type = esc(ex.args[2])
    interface = esc(ex.args[3])

    quote
        let
            old_implemented = ExtendableInterfaces.implements($type)
            new_implemented = ExtendableInterfaces.ancestors($interface())
            implemented = ExtendableInterfaces.tuple_union(new_implemented, old_implemented)
            ExtendableInterfaces.implements(::Type{$type}) = implemented
        end
    end
end
