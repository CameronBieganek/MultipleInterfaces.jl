

module MultipleInterfaces

export ≼, ⋠
export @idispatch, @interface, @type
export all_required_methods, implements, is_subinterface, required_methods, superinterfaces
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end
abstract type ConcreteInterface end

include("utils.jl")
include("interface.jl")
include("intersection.jl")
include("dispatch.jl")

end
