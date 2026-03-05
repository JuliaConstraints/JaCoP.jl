# THIS IS NOT A FULL JAVA WRAPPER!
# Even though the name seems to imply it, it only provides some convenience
# definitions for use in the MOI wrapper.

## Type definitions
# These correspond to Java types (which are directly returned by the functions
# in this binder). In particular, the inheritance defined in Java is not brought
# back to Julia.
const Store = @jimport org.jacop.core.Store

const Var = @jimport org.jacop.core.Var
const BooleanVar = @jimport org.jacop.core.BooleanVar
const IntVar = @jimport org.jacop.core.IntVar
const SetVar = @jimport org.jacop.set.core.SetVar
const FloatVar = @jimport org.jacop.floats.core.FloatVar
const CircuitVar = @jimport org.jacop.constraints.CircuitVar

const Constraint = @jimport org.jacop.constraints.Constraint
const LinearInt = @jimport org.jacop.constraints.LinearInt
const LinearFloat = @jimport org.jacop.floats.constraints.LinearFloat
const Alldifferent = @jimport org.jacop.constraints.Alldifferent
const In = @jimport org.jacop.constraints.In
const XeqC = @jimport org.jacop.constraints.XeqC
const XlteqC = @jimport org.jacop.constraints.XlteqC
const XgteqC = @jimport org.jacop.constraints.XgteqC

# Search types.
const DepthFirstSearch = @jimport org.jacop.search.DepthFirstSearch
const InputOrderSelect = @jimport org.jacop.search.InputOrderSelect
const IndomainMin = @jimport org.jacop.search.IndomainMin
const Indomain = @jimport org.jacop.search.Indomain
const SelectChoicePoint = @jimport org.jacop.search.SelectChoicePoint

# Unions of types to model Java type hierarchy.

const Variable = Union{BooleanVar, IntVar, SetVar, FloatVar, CircuitVar}

# Add a constraint to a store.

function jacop_add_constraint_to_store(store::Store, constraint)
    jcall(store, "impose", Nothing, (Constraint,), constraint)
    return
end
