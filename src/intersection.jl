

const InterfaceInstances = Tuple{ConcreteInterface, ConcreteInterface, Vararg{ConcreteInterface}}


struct Intersection{T <: InterfaceInstances} <: Interface
    interfaces::T
end


function normalize(interfaces::InterfaceInstances)
    simpler = remove_superinterfaces(interfaces)
    if length(simpler) == 1
        typeof(simpler[1])
    else
        sorted_simpler = sort(collect(simpler), by = string ∘ typeof)
        Intersection(tuple(sorted_simpler...))
    end
end


# `&` is the public interface for interface intersection, e.g. `A & B`.

Base.:&(::Type{S}, ::Type{S}) where {S <: Intersection} = S
Base.:&(::Type{S}, ::Type{S}) where {S <: ConcreteInterface} = S
Base.:&(S::Type{<:ConcreteInterface}, T::Type{<:ConcreteInterface}) = normalize((S(), T()))
Base.:&(s::Intersection, T::Type{<:ConcreteInterface}) = normalize((s.interfaces..., T()))
Base.:&(S::Type{<:ConcreteInterface}, t::Intersection) = normalize((S(), t.interfaces...))
Base.:&(s::Intersection, t::Intersection) = normalize((s.interfaces..., t.interfaces...))


function Base.show(io::IO, i::Intersection)
    for interface in i.interfaces[1:end-1]
        print(io, typeof(interface), " & ")
    end
    print(io, typeof(i.interfaces[end]))
end


function _is_subinterface(sub::ConcreteInterface, super::Intersection)
    all_t(x -> _is_subinterface(sub, x), super.interfaces)
end

function _is_subinterface(sub::Intersection, super::ConcreteInterface)
    any_t(x -> _is_subinterface(x, super), sub.interfaces)
end

function _is_subinterface(left::Intersection, right::Intersection)
    all_t(right.interfaces) do right_concrete
        any_t(left_concrete -> _is_subinterface(left_concrete, right_concrete), left.interfaces)
    end
end


is_subinterface(S::Type{<:ConcreteInterface}, t::Intersection) = _is_subinterface(S(), t)
is_subinterface(s::Intersection, T::Type{<:ConcreteInterface}) = _is_subinterface(s, T())
is_subinterface(s::Intersection, t::Intersection) = _is_subinterface(s, t)


# NOTE: For `Base.==` on interface intersections, we rely on the default fallback to `===`.
