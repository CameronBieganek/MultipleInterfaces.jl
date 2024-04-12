

# Define the arrows to point from subinterfaces to superinterfaces.
children(interface) = superinterfaces(interface)


function in_tuple(x::S, t::Tuple{T, Vararg}) where {S, T}
    S === T || in_tuple(x, Base.tail(t))
end

in_tuple(::T, t::Tuple{T, Vararg}) where {T} = true
in_tuple(_, t::Tuple{}) = false


function visit_node(order::Tuple, interface)
    in_tuple(interface, order) && return order
    new_order = visit_children(order, children(interface))
    (interface, new_order...)
end

function visit_children(order::Tuple, children::Tuple)
    new_order = visit_node(order, children[1])
    visit_children(new_order, Base.tail(children))
end

visit_children(order::Tuple, ::Tuple{}) = order


topo_sort(to_visit::Tuple) = _topo_sort((), to_visit)

function _topo_sort(order::Tuple, to_visit::Tuple)
    new_order = visit_node(order, to_visit[1])
    _topo_sort(new_order, Base.tail(to_visit))
end

_topo_sort(order::Tuple, unvisited::Tuple{}) = order
