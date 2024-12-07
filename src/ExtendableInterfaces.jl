

module ExtendableInterfaces

export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export Interface
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end

include("utils.jl")
include("interface.jl")
include("dispatch.jl")

end
