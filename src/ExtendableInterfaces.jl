

module ExtendableInterfaces

using UUIDs

export ≼, ⋠
export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end
abstract type ConcreteInterface end

# TODO: Update `superinterfaces` and `required_methods` so they work on interface intersections?
# TODO: Allow long-form function definitions and keyword arguments in `@idispatch`.

include("utils.jl")
include("interface.jl")
include("intersection.jl")
include("dispatch.jl")

end
