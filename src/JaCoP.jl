module JaCoP

using JavaCall
import MathOptInterface
import ConstraintProgrammingExtensions

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const CleverDicts = MOIU.CleverDicts
const CP = ConstraintProgrammingExtensions

# Check if the package has been built correctly.
if isfile(joinpath(dirname(@__FILE__), "..", "deps", "deps.jl"))
    include("../deps/deps.jl")
else
    error(
        "JaCoP not properly installed. Please run `Pkg.build(\"JaCoP\")` or `]build JaCoP`",
    )
end

if !@isdefined(libjacopjava)
    error(
        "JaCoP not properly built. There probably was a problem when running `Pkg.build(\"JaCoP\")` or `]build JaCoP`",
    )
end

# Initialise the package by setting the right parameters for Java. This assumes
# no other code uses JavaCall...
function __init__()
    if get(ENV, "JULIA_REGISTRYCI_AUTOMERGE", "") != "true"
        jacop_java_init()
    end
end

"""
    jacop_java_init(init_java::Bool=true)

Initialises the JVM to be able to use JaCoP. This function must be called once
per Julia process that uses JaCoP.

By default, this function automatically starts the JVM link (from JavaCall.jl).
If other parts of the application require access to the JVM, this 
initialisation can be disabled by setting `init_java` to `false`.
In that case, this function *MUST* be called before `JavaCall.init()`, because
it sets Java's CLASSPATH to include JaCoP.
"""
function jacop_java_init(init_java::Bool=true)
    JavaCall.addClassPath(libjacopjava)
    if init_java
        JavaCall.init()
    end
    return
end

include("java_wrapper.jl")
include("MOI/wrapper.jl")
include("MOI/parse.jl") # Must come after wrapper.jl.
include("MOI/wrapper_constraints_cp.jl")
include("MOI/wrapper_constraints_mo.jl")
include("MOI/wrapper_constraints_singlevar.jl")
include("MOI/wrapper_constraints.jl")
include("MOI/wrapper_variables.jl")

end
