

module ExtendableInterfaces

using UUIDs

export ≼, ⋠
export @idispatch, @interface, @type
export implements, is_subinterface, required_methods, superinterfaces
export NoMatchingIDispatchMethodError, SingleArgumentAmbiguityError, MultipleArgumentAmbiguityError

abstract type Interface end
abstract type ConcreteInterface end

# TODO: Use hidden names for the methods that are overloaded by macros, and
# add something like `import ExtendableInterfaces: var"#interface_signatures#"` to
# the macro expansions.

# TODO: Update `superinterfaces` and `required_methods` so they work on interface intersections?

# TODO:
# - Update `@idispatch` to work with interface intersections.
# - Make sure that method redefinition works properly.

# TODO: Allow definitions like this?
# @idispatch foo(x::Int, y) = 1
# ...that probaby won't work...

include("utils.jl")
include("interface.jl")
include("intersection.jl")
include("dispatch.jl")

end
