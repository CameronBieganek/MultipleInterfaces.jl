

using Test

@testset "ExtendableInterfaces.jl" begin
    include("utils.jl")
    include("interface.jl")
    include("intersection.jl")
    include("dispatch.jl")
    include("intersection_dispatch.jl")
end

println("\nTesting inference...")
include("test_inference.jl")
println("Inference successful.\n")
