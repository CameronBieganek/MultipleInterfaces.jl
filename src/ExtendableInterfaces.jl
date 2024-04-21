

module ExtendableInterfaces

export @declare, @implements, @interface, @polymorphic
export implements, required_methods, superinterfaces

include("interface.jl")
include("implements.jl")
include("polymorphic.jl")
include("dispatch.jl")

end
