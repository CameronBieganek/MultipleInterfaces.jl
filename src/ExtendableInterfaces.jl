

module ExtendableInterfaces

export @adhoc, @declare, @interface, @type
export implements, required_methods, superinterfaces
export Interface, InterfaceDispatchError

include("interface.jl")
include("implements.jl")
include("adhoc.jl")
include("dispatch.jl")

end
