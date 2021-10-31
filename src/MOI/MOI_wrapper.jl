@enum(VariableType, CONTINUOUS, BINARY, INTEGER, SET, CIRCUIT)

mutable struct VariableInfo
    index::MOI.VariableIndex
    variable::Variable
    name::String
    type::VariableType

    # Variable bounds: either integers or floats. Needed for is_valid on VariableIndex 
    # and bound constraints.
    lb::Real
    ub::Real
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

    # A flag to keep track of MOI.Silent.
    silent::Bool

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

    # # Handle callbacks. WIP.
    # callback_state::CallbackState

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

        MOI.set(model, MOI.Silent(), false)

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
    model.inner = JavaCPOModel()
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
    # model.callback_state = CB_NONE
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
    # model.callback_state != CB_NONE && return false
    return true
end

MOI.get(::Optimizer, ::MOI.SolverName) = "JaCoP"
