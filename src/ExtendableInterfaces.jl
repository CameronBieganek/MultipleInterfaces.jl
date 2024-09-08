

module ExtendableInterfaces

export @idispatch, @interface, @type
export implements, required_methods, superinterfaces
export Interface, InterfaceDispatchError

abstract type Interface end

include("utils.jl")
include("interface.jl")
include("dispatch.jl")

end
