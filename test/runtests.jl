

using Test

@testset "ExtendableInterfaces.jl" begin
    include("interface.jl")
    include("polymorphic.jl")
    include("implements.jl")
    include("dispatch.jl")
end
