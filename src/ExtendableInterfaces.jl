

module ExtendableInterfaces

export ≼, ⋠
export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export Interface
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end

function required_methods end
function superinterfaces end

include("utils.jl")
include("interface.jl")
include("dispatch.jl")

end
