

using Test

@testset "ExtendableInterfaces.jl" begin
    include("interface.jl")
    include("dispatch.jl")
end

println("\nTesting inference...")
include("test_inference.jl")
println("Inference successful.\n")
