

module ExtendableInterfaces

export @declare, @implement, @interface, @polymorphic
export required_methods, superinterfaces

include("interface.jl")
include("implement.jl")
include("polymorphic.jl")
include("dispatch.jl")

end
