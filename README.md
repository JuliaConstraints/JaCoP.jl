# JaCoP.jl

JaCoP.jl is a wrapper for the 
[JaCoP constraint-programming solver](https://github.com/radsz/jacop).

JaCoP.jl only proposes an implementation of the interface defined by 
[MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl) and by
[ConstraintProgrammingExtensions.jl](https://github.com/dourouc05/ConstraintProgrammingExtensions.jl).
It does not provide access to the low-level Java API.

*Note: This wrapper is maintained by the community and is not officially
supported by the JaCoP project. If you are interested in official support for
JaCoP in Julia, let them know!*

Unlike the other packages for constraint programming in Julia, JaCoP.jl
requires Julia 1.6 (due to the `Downloads.jl` standard package).

The JaCoP library is automatically downloaded when building this package in a
version that it supports. However, as JaCoP is a Java library, you will need
a working JVM on your machine that is compatible with
[JavaCall.jl](https://github.com/JuliaInterop/JavaCall.jl). Typically, this
reduces to having access to a JVM in your `PATH` or `JAVA_HOME`
environment variables. (If you want to use your own JaCoP binary, you can 
tweak the `deps/deps.jl` that is generated while building the package.)
