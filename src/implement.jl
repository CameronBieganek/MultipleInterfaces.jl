

struct Implements end
struct DoesNotImplement end

implements(obj, interface) = DoesNotImplement()


# ImplementationError <: Exception

# function test_implementation(type, interface, methods)
#     if !issetequal(requiredmethods(interface), methods)
#         # TODO: Make custom exception and make error message more detailed.
#         error("The $type type does not fully implement the $interface interface.")
#     end
# end


macro implement(type, as::Symbol, interface, methods)
    as === :as || error("Invalid interface implementation syntax.")

    ex = quote
        $methods
        ExtendableInterfaces.implements(::$type, ::$interface) = ExtendableInterfaces.Implements()
    end

    esc(ex)
end
