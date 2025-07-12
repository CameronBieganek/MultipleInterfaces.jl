

module ExtendableInterfaces

export ≼, ⋠
export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end
abstract type ConcreteInterface end

# TODO: Update `required_methods` so it works on interface intersections?
# TODO: Add `all_required_methods`?
# TODO: Add `all_superinterfaces`?
# TODO: Allow long-form function definitions and keyword arguments in `@idispatch`.
# TODO: Allow this syntax: `@interface A: foo, bar`, or `@interface A extends B, C: foo, bar`.

include("utils.jl")
include("interface.jl")
include("intersection.jl")
include("dispatch.jl")

end
