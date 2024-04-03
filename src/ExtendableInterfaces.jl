

module ExtendableInterfaces

export @implement, @interface
export requiredmethods, superinterfaces

include("interface.jl")
include("implement.jl")

end
