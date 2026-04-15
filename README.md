# JaCoP.jl

JaCoP.jl is a wrapper for the 
[JaCoP constraint-programming solver](https://github.com/radsz/jacop).

JaCoP.jl only proposes an implementation of the interface defined by 
[MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl) and by
[ConstraintProgrammingExtensions.jl](https://github.com/dourouc05/ConstraintProgrammingExtensions.jl).
It does not provide access to the low-level Java API.

## Affiliation

This wrapper is maintained by the community and is not officially
supported by the JaCoP project. If you are interested in official support for
JaCoP in Julia, let them know!

## Installation

Install JaCoP as follows:
```julia
import Pkg
Pkg.add("JaCoP")
```

The JaCoP library is automatically downloaded when building this package in a
version that it supports. However, as JaCoP is a Java library, you will need
a working JVM on your machine that is compatible with
[JavaCall.jl](https://github.com/JuliaInterop/JavaCall.jl). Typically, this
reduces to having access to a JVM in your `PATH` or `JAVA_HOME`
environment variables. (If you want to use your own JaCoP binary, you can 
tweak the `deps/deps.jl` that is generated while building the package.)

> [!WARNING]
> JaCoP uses [JavaCall](https://github.com/JuliaInterop/JavaCall.jl) which requires
> launching Julia with [`JULIA_NUM_THREADS=1 JULIA_COPY_STACKS=1 julia`](https://github.com/JuliaInterop/JavaCall.jl?tab=readme-ov-file#macos-and-linux)
> on MaxOS and Linux. See [here](https://github.com/JuliaInterop/JavaCall.jl?tab=readme-ov-file#windows) for Windows.

## Use with JuMP

To use JaCoP with JuMP, use `JaCoP.Optimizer`:

```julia
using JuMP, JaCoP
model = Model(JaCoP.Optimizer)
```

> [!WARNING]
> There is a known issue where JaCoP.jl segfaults if you delete variables or constraints.

> [!TIP]
> If you experience segfaults (e.g., on Julia 1.12.6+), try adding `-Xss2m` to
> increase the JVM thread stack size before initializing JavaCall:
> ```julia
> JavaCall.addOpts("-Xss2m")
> ```
> JaCoP.jl [already does this automatically](https://github.com/JuliaConstraints/JaCoP.jl/blob/39f387de53fed270cba4368079502a4da7ac01bb/src/JaCoP.jl#L50-L52), but if you initialize JavaCall
> yourself (by passing `init_java=false` to `jacop_java_init`), you may need
> to add this option manually.
