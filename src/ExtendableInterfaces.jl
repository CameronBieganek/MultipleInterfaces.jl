

module ExtendableInterfaces

export ≼, ⋠
export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end

# TODO: Update these so they operate on `Interface` types rather than instances.
function required_methods end
function superinterfaces end

include("utils.jl")
include("interface.jl")
include("intersection.jl")
include("dispatch.jl")

end
