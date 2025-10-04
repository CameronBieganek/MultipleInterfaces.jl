


module Issue5

# https://github.com/CameronBieganek/MultipleInterfaces.jl/issues/5

using Test
using MultipleInterfaces

struct Fox end

function a end
@interface A begin a end

# The easiest way to test top-level definitions like this is to just let it fail outside
# of a test. I'm not sure if there's a better approach.
@idispatch foo(a: A, x::Fox) = 1

end
