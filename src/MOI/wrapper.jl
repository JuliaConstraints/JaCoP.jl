# Largely inspired by CPLEXCP.jl.
# Main differences: 
# - no support for quadratic functions (for now?)
# - no support for adding int/bool constraint on variables (only at creation)
# TODOs: 
# - objective
# - var/cons name
# - parameters: number of threads, time limit, raw
# - looks like JaCoP is as immutable as possible: looks like it's impossible to change the name of a variable, e.g.

@enum(VariableType, CONTINUOUS, BINARY, INTEGER, SET, CIRCUIT)

mutable struct VariableInfo
    index::MOI.VariableIndex
    variable::Variable
    name::String # TODO: remove me?
    type::VariableType

    # Variable bounds: either integers or floats. Needed for is_valid on VariableIndex 
    # and bound constraints.
    lb::Union{Nothing, Integer, Float64}
    ub::Union{Nothing, Integer, Float64}
end

function VariableInfo(index::MOI.VariableIndex, variable::Variable)
    return VariableInfo(index, variable, "", INTEGER, nothing, nothing)
end

mutable struct ConstraintInfo
    # Only necessary information to access an existing constraint, delete it when needed.
    index::MOI.ConstraintIndex
    constraint::Union{JavaObject, Nothing}
    f::Union{MOI.AbstractScalarFunction, MOI.AbstractVectorFunction}
    set::MOI.AbstractSet
    name::String
end

function ConstraintInfo(
    index::MOI.ConstraintIndex,
    constraint::Union{JavaObject, Nothing},
    f::Union{MOI.AbstractScalarFunction, MOI.AbstractVectorFunction},
    set::MOI.AbstractSet,
)
    return ConstraintInfo(index, constraint, f, set, "")
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    # The low-level JaCoP store.
    inner::Store

    # The model name.
    name::String

    # A mapping from the MOI.VariableIndex to the CPLEX variable object.
    # VariableInfo also stores some additional fields like the type of variable.
    variable_info::CleverDicts.CleverDict{MOI.VariableIndex, VariableInfo}

    # A mapping from the MOI.ConstraintIndex to the CPLEX variable object.
    # VariableInfo also stores some additional fields like the type of variable.
    constraint_info::Dict{MOI.ConstraintIndex, ConstraintInfo}

    # Objective sense (min/max/feasibility). Required for MOI tests.
    objective_sense::MOI.OptimizationSense
    # Type and value of the objective function if set; nothing otherwise.
    objective_function_type::Union{Nothing, DataType}
    objective_function::Union{Nothing, MOI.VariableIndex, MOI.ScalarAffineFunction{Float64}}

    # Cached solution state.
    termination_status::MOI.TerminationStatusCode
    primal_status::MOI.ResultStatusCode

    """
        Optimizer()

    Create a new Optimizer object.
    """
    function Optimizer()
        model = new()
        model.inner = Store()

        model.variable_info =
            CleverDicts.CleverDict{MOI.VariableIndex, VariableInfo}()
        model.constraint_info = Dict{MOI.ConstraintIndex, ConstraintInfo}()

        model.termination_status = MOI.OPTIMIZE_NOT_CALLED
        model.primal_status = MOI.NO_SOLUTION

        model.objective_sense = MOI.FEASIBILITY_SENSE
        model.objective_function_type = nothing
        model.objective_function = nothing

        MOI.empty!(model)
        return model
    end
end

function MOI.empty!(model::Optimizer)
    model.inner = Store()
    model.name = ""
    empty!(model.variable_info)
    empty!(model.constraint_info)
    model.objective_sense = MOI.FEASIBILITY_SENSE
    model.objective_function_type = nothing
    model.objective_function = nothing
    model.termination_status = MOI.OPTIMIZE_NOT_CALLED
    model.primal_status = MOI.NO_SOLUTION
    return
end

function MOI.is_empty(model::Optimizer)
    !isempty(model.name) && return false
    !isempty(model.variable_info) && return false
    !isempty(model.constraint_info) && return false
    model.objective_sense != MOI.FEASIBILITY_SENSE && return false
    (model.objective_function_type !== nothing || model.objective_function !== nothing) && return false
    model.termination_status != MOI.OPTIMIZE_NOT_CALLED && return false
    return true
end

MOI.get(::Optimizer, ::MOI.SolverName) = "JaCoP"

## Types of objectives and constraints that are supported.

function MOI.supports(
    ::Optimizer,
    ::MOI.ObjectiveFunction{F},
) where {F <: Union{MOI.VariableIndex, MOI.ScalarAffineFunction{Float64}}}
    return true
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveFunction{F}) where {F}
    if model.objective_function_type !== F
        error(
            "Objective function type is $(model.objective_function_type), not $F.",
        )
    end
    return model.objective_function::F
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveFunction{F},
    f::F,
) where {F <: Union{MOI.VariableIndex, MOI.ScalarAffineFunction{Float64}}}
    model.objective_function_type = F
    model.objective_function = f
    return
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VariableIndex},
    ::Type{F},
) where {
    T <: Union{Int32, Float64},
    F <:
    Union{MOI.EqualTo{T}, MOI.LessThan{T}, MOI.GreaterThan{T}, MOI.Interval{T}},
}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{T}},
    ::Type{F},
) where {
    T <: Union{Int32, Float64},
    F <: Union{MOI.EqualTo{T}, MOI.LessThan{T}, MOI.GreaterThan{T}},
    # No interval!
}
    return true
end

# MOI.supports(::Optimizer, ::MOI.NumberOfThreads) = true
# MOI.supports(::Optimizer, ::MOI.TimeLimitSec) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
# MOI.supports(::Optimizer, ::MOI.RawOptimizerAttribute) = true

MOI.supports_incremental_interface(::Optimizer) = true

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    return MOI.Utilities.default_copy_to(dest, src)
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveSense)
    return model.objective_sense
end

function MOI.set(model::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    model.objective_sense = sense
    return
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveFunctionType)
    return model.objective_function_type
end

function MOI.get(model::Optimizer, ::MOI.ListOfModelAttributesSet)
    attributes = Any[MOI.ObjectiveSense()]
    typ = model.objective_function_type
    if typ !== nothing
        push!(attributes, MOI.ObjectiveFunction{typ}())
    end
    return attributes
end

function MOI.optimize!(model::Optimizer)
    int_vars = IntVar[
        info.variable for
        info in values(model.variable_info) if info.variable isa IntVar
    ]
    float_vars = FloatVar[
        info.variable for
        info in values(model.variable_info) if info.variable isa FloatVar
    ]
    if isempty(int_vars) && isempty(float_vars)
        model.termination_status = MOI.OPTIMAL
        model.primal_status = MOI.FEASIBLE_POINT
        return
    end
    result = true
    if !isempty(int_vars)
        search = DepthFirstSearch(())
        indomain = IndomainMin(())
        select = InputOrderSelect(
            (Store, Vector{Var}, Indomain),
            model.inner,
            int_vars,
            indomain,
        )
        result = jcall(
            search,
            "labeling",
            jboolean,
            (Store, SelectChoicePoint),
            model.inner,
            select,
        ) != 0
    end
    if result && !isempty(float_vars)
        search_float = DepthFirstSearch(())
        comparator = SmallestDomainFloat(())
        # JNI: use Var[] (FloatVar[] passes as subclass); 3rd arg is ComparatorVariable.
        select_float = SplitSelectFloat(
            (Store, Vector{Var}, ComparatorVariable),
            model.inner,
            float_vars,
            comparator,
        )
        result = jcall(
            search_float,
            "labeling",
            jboolean,
            (Store, SelectChoicePoint),
            model.inner,
            select_float,
        ) != 0
    end
    if result
        model.termination_status = MOI.OPTIMAL
        model.primal_status = MOI.FEASIBLE_POINT
    else
        model.termination_status = MOI.INFEASIBLE
        model.primal_status = MOI.NO_SOLUTION
    end
    return
end

function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    return model.termination_status
end

function MOI.get(model::Optimizer, ::MOI.PrimalStatus)
    return model.primal_status
end

function MOI.get(model::Optimizer, ::MOI.ResultCount)
    return model.primal_status == MOI.FEASIBLE_POINT ? 1 : 0
end

function MOI.get(model::Optimizer, attr::MOI.VariablePrimal, vi::MOI.VariableIndex)
    MOI.check_result_index_bounds(model, attr)
    info = _info(model, vi)
    v = info.variable
    if v isa FloatVar
        return Float64(jcall(v, "value", jdouble, ()))
    else
        return Int(jcall(v, "value", jint, ()))
    end
end

function _eval_objective(model::Optimizer)
    if model.objective_sense == MOI.FEASIBILITY_SENSE
        return 0.0
    end
    f = model.objective_function
    if f === nothing
        return 0.0
    elseif f isa MOI.VariableIndex
        return Float64(MOI.get(model, MOI.VariablePrimal(1), f))
    else
        # ScalarAffineFunction
        val = Float64(f.constant)
        for term in f.terms
            val += term.coefficient * Float64(MOI.get(model, MOI.VariablePrimal(1), term.variable))
        end
        return val
    end
end

function MOI.get(model::Optimizer, attr::MOI.ObjectiveValue)
    MOI.check_result_index_bounds(model, attr)
    return _eval_objective(model)
end

