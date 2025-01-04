

module ExtendableInterfaces

export ≼, ⋠
export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end

# TODO: Use hidden names for the methods that are overloaded by macros, and
# add something like `import ExtendableInterfaces: var"#interface_signatures#"` to
# the macro expansions.

include("utils.jl")
include("interface.jl")
include("intersection.jl")
include("dispatch.jl")

end
