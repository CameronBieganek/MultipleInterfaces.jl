

module ExtendableInterfaces

export @declare, @implement, @interface, @polymorphic
export requiredmethods, superinterfaces

include("interface.jl")
include("implement.jl")
include("polymorphic.jl")
include("dispatch.jl")

end
