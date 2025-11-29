


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



####################################################################################################

module Issue8

# https://github.com/CameronBieganek/MultipleInterfaces.jl/issues/8

using Test
using MultipleInterfaces

function a end
@interface A begin a end

struct Ant end
@type Ant implements A

f(x) = x

@idispatch g(x: A) = f(x)

@testset "issue 8" begin
    @test g(Ant()) == Ant()
end

end



####################################################################################################

module Issue11

# https://github.com/CameronBieganek/MultipleInterfaces.jl/issues/11

using Test
using MultipleInterfaces


module Foo
    using MultipleInterfaces

    function a end

    @interface A begin a end

    @idispatch f(x: A) = 1
end


using .Foo: A
import .Foo: f

function b end
@interface B begin b end

struct Ant end
struct Bear end

@type Ant implements A
@type Bear implements B

@idispatch f(x: B) = 2

@testset "issue 11" begin
    @test f(Ant()) == 1
    @test f(Bear()) == 2
end

end



####################################################################################################

module Issue12

# https://github.com/CameronBieganek/MultipleInterfaces.jl/issues/12

using Test
using MultipleInterfaces

module Foo
    struct A end
end

module Bar
    struct A end
end

struct A end

function b end
@interface B begin b end

struct Bear end
@type Bear implements B

@idispatch foo(a::A, b: B) = 1
@idispatch foo(a::Foo.A, b: B) = 2
@idispatch foo(a::Bar.A, b: B) = 3

@testset "issue 12" begin
    @test foo(A(), Bear()) == 1
    @test foo(Foo.A(), Bear()) == 2
    @test foo(Bar.A(), Bear()) == 3
end

end



####################################################################################################

module Issue13

# https://github.com/CameronBieganek/MultipleInterfaces.jl/issues/13

using Test
using MultipleInterfaces


module Foo
    using MultipleInterfaces

    function a end

    @interface A begin a end

    @idispatch f(x: A) = 1

    export f, A
end


using .Foo

function b end
@interface B begin b end

struct Ant end
struct Bear end

@type Ant implements A
@type Bear implements B

@idispatch Foo.f(x: B) = 2

@testset "issue 13" begin
    @test f(Ant()) == 1
    @test f(Bear()) == 2
end

end
