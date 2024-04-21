

implements(obj, interface) = false


macro implements(ex)
    type = ex.args[2]
    interface = ex.args[3]
    esc(:(ExtendableInterfaces.implements(::$type, ::$interface) = true))
end
