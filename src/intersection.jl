

const InterfaceInstances = Tuple{Interface, Interface, Vararg{Interface}}


struct Intersection{T <: InterfaceInstances} <: Interface
    interfaces::T
end


function simplify(interfaces::InterfaceInstances)
    simpler = remove_superinterfaces(interfaces)
    if length(simpler) == 1
        typeof(simpler[1])
    else
        Intersection(simpler)
    end
end


# `&` is the public interface for interface intersection, e.g. `A & B`.

Base.:&(::Type{S}, ::Type{S}) where {S <: Interface} = S
Base.:&(S::Type{<:Interface}, T::Type{<:Interface}) = simplify((S(), T()))
Base.:&(s::Intersection, T::Type{<:Interface}) = simplify((s.interfaces..., T()))
Base.:&(S::Type{<:Interface}, t::Intersection) = simplify((S(), t.interfaces...))
Base.:&(s::Intersection, t::Intersection) = simplify((s.interfaces, t.interfaces...))


Base.:(==)(s::Intersection, t::Intersection) = issetequal(s.interfaces, t.interfaces)


function Base.show(io::IO, i::Intersection)
    for interface in i.interfaces[1:end-1]
        print(io, typeof(interface), " & ")
    end
    print(io, typeof(i.interfaces[end]))
end
