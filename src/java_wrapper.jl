# THIS IS NOT A FULL JAVA WRAPPER!
# Even though the name seems to imply it, it only provides some convenience
# definitions for use in the MOI wrapper.

## Type definitions
# These correspond to Java types (which are directly returned by the functions
# in this binder). In particular, the inheritance defined in Java is not brought
# back to Julia.
const Store = JavaObject{Symbol("org.jacop.core.Store")}

const BooleanVar = JavaObject{Symbol("org.jacop.core.BooleanVar")}
const IntVar = JavaObject{Symbol("org.jacop.core.IntVar")}
const SetVar = JavaObject{Symbol("org.jacop.set.core.FloatVar")}
const FloatVar = JavaObject{Symbol("org.jacop.floats.core.FloatVar")}
const CircuitVar = JavaObject{Symbol("org.jacop.constraints.CircuitVar")}

const Constraint = JavaObject{Symbol("org.jacop.constraints.Constraint")}

# Unions of types to model Java type hierarchy.

const Variable = Union{
    BooleanVar,
    IntVar,
    SetVar,
    FloatVar,
    CircuitVar,
}
