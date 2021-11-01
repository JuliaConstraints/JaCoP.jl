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
    return VariableInfo(
        index,
        variable,
        "",
        INTEGER,
        nothing,
        nothing,
    )
end

mutable struct ConstraintInfo
    # Only necessary information to access an existing constraint, delete it when needed.
    index::MOI.ConstraintIndex
    constraint::Constraint
    f::Union{MOI.AbstractScalarFunction, MOI.AbstractVectorFunction}
    set::MOI.AbstractSet
    name::String
end

function ConstraintInfo(
    index::MOI.ConstraintIndex,
    constraint::Constraint,
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

    # # Memorise the objective sense and the function separately, as the Concert
    # # API forces to give both at the same time.
    # objective_sense::MOI.OptimizationSense
    # objective_function::Union{Nothing, MOI.AbstractScalarFunction}
    # objective_function_cp::Union{Nothing, NumExpr}
    # objective_cp::Union{Nothing, IloObjective}

    # # Cache parts of a solution.
    # cached_solution_state::Union{Nothing, Bool}

    # # Mappings from variable and constraint names to their indices. These are
    # # lazily built on-demand, so most of the time, they are `nothing`.
    # # The solver's functionality is not useful in this case, as it can only
    # # handle integer variables. Moreover, bound constraints do not have names
    # # for the solver.
    # name_to_variable::Union{Nothing, Dict{String, MOI.VariableIndex}}
    # name_to_constraint::Union{Nothing, Dict{String, MOI.ConstraintIndex}}

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

        # model.objective_sense = MOI.FEASIBILITY_SENSE
        # model.objective_function = nothing
        # model.objective_function_cp = nothing
        # model.objective_cp = nothing

        # model.cached_solution_state = nothing
        # model.callback_state = CB_NONE

        MOI.empty!(model)
        return model
    end
end

Base.show(io::IO, model::Optimizer) = show(io, model.inner)

function MOI.empty!(model::Optimizer)
    model.inner = Store()
    model.name = ""
    empty!(model.variable_info)
    empty!(model.constraint_info)

    # model.objective_sense = MOI.FEASIBILITY_SENSE
    # model.objective_function = nothing
    # model.objective_function_cp = nothing
    # model.objective_cp = nothing

    # model.cached_solution_state = nothing
    # model.name_to_variable = nothing
    # model.name_to_constraint = nothing
    return
end

function MOI.is_empty(model::Optimizer)
    !isempty(model.name) && return false
    !isempty(model.variable_info) && return false
    !isempty(model.constraint_info) && return false
    # model.objective_sense != MOI.FEASIBILITY_SENSE && return false
    # model.objective_function !== nothing && return false
    # model.objective_function_cp !== nothing && return false
    # model.objective_cp !== nothing && return false
    # model.name_to_variable !== nothing && return false
    # model.name_to_constraint !== nothing && return false
    # model.cached_solution_state !== nothing && return false
    return true
end

MOI.get(::Optimizer, ::MOI.SolverName) = "JaCoP"

## Types of objectives and constraints that are supported.

function MOI.supports(
    ::Optimizer,
    ::MOI.ObjectiveFunction{F},
) where {
    F <: Union{
        MOI.VariableIndex,
        MOI.ScalarAffineFunction{Float64},
    },
}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VariableIndex},
    ::Type{F},
) where {
    T <: Union{Int32, Float64},
    F <: Union{
        MOI.EqualTo{T},
        MOI.LessThan{T},
        MOI.GreaterThan{T},
        MOI.Interval{T},
    },
}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{T}},
    ::Type{F},
) where {
    T <: Union{Int32, Float64},
    F <:
    Union{MOI.EqualTo{T}, MOI.LessThan{T}, MOI.GreaterThan{T}},
    # No interval!
}
    return true
end

MOI.supports(::Optimizer, ::MOI.VariableName, ::Type{MOI.VariableIndex}) = true
function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintName,
    ::Type{<:MOI.ConstraintIndex},
)
    return true
end

MOI.supports(::Optimizer, ::MOI.Name) = true
# MOI.supports(::Optimizer, ::MOI.NumberOfThreads) = true
# MOI.supports(::Optimizer, ::MOI.TimeLimitSec) = true
# MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
# MOI.supports(::Optimizer, ::MOI.RawOptimizerAttribute) = true

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    return MOI.Utilities.default_copy_to(dest, src)
end

function MOI.get(::Optimizer, ::MOI.ListOfVariableAttributesSet)
    return MOI.AbstractVariableAttribute[MOI.VariableName()]
end

function MOI.get(model::Optimizer, ::MOI.ListOfModelAttributesSet)
    attributes = Any[MOI.ObjectiveSense()]
    typ = MOI.get(model, MOI.ObjectiveFunctionType())
    if typ !== nothing
        push!(attributes, MOI.ObjectiveFunction{typ}())
    end
    if MOI.get(model, MOI.Name()) != ""
        push!(attributes, MOI.Name())
    end
    return attributes
end

function MOI.get(::Optimizer, ::MOI.ListOfConstraintAttributesSet)
    return MOI.AbstractConstraintAttribute[MOI.ConstraintName()]
end
