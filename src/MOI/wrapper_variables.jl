function _info(model::Optimizer, key::MOI.VariableIndex)
    if haskey(model.variable_info, key)
        return model.variable_info[key]
    end
    throw(MOI.InvalidIndex(key))
    return
end

function _make_var(model::Optimizer, variable::Variable)
    # Initialize `VariableInfo` with a dummy `VariableIndex` and a column,
    # because we need `add_item` to tell us what the `VariableIndex` is.
    index = CleverDicts.add_item(
        model.variable_info,
        VariableInfo(MOI.VariableIndex(0), variable),
    )
    _info(model, index).index = index
    return index
end

function _make_var(
    model::Optimizer,
    variable::Variable,
    set::MOI.AbstractScalarSet,
)
    index = _make_var(model, variable)
    S = typeof(set)
    return index, MOI.ConstraintIndex{MOI.VariableIndex, S}(index.value)
end

function _make_vars(model::Optimizer, variables::Vector{<:Variable})
    # Barely used, because add_constrained_variables may have variable sets (except for AbstractVectorSet).
    # Only implemented in the unconstrained case.
    indices = Vector{MOI.VariableIndex}(undef, length(variables))
    for i in 1:length(variables)
        indices[i] = CleverDicts.add_item(
            model.variable_info,
            VariableInfo(MOI.VariableIndex(0), variables[i]),
        )
        _info(model, indices[i]).index = indices[i]
    end
    return indices
end

function _sanitise_bounds(lb::Real, ub::Real, T)
    if lb === nothing
        lb = typemin(T)
    end
    if ub === nothing
        ub = typemax(T)
    end
    return lb, ub
end

function _make_floatvar(
    model::Optimizer,
    set::MOI.AbstractScalarSet;
    lb::Union{Nothing, Float64}=nothing,
    ub::Union{Nothing, Float64}=nothing,
)
    v = if lb === nothing && ub === nothing
        FloatVar(
            (Store,),
            model.inner,
        )
    else
        lb_, ub_ = _sanitise_bounds(lb, ub, Float64)
        FloatVar(
            (Store, jdouble, jdouble),
            model.inner,
            lb_,
            ub_,
        )
    end

    vindex, cindex = _make_var(model, v, set)
    _info(model, vindex).type = CONTINUOUS
    _info(model, vindex).lb = lb
    _info(model, vindex).ub = ub
    return vindex, cindex
end

function _make_intvar(
    model::Optimizer,
    set::MOI.AbstractScalarSet;
    lb::Int32=typemin(Int32),
    ub::Int32=typemax(Int32),
)
    v = if lb === nothing && ub === nothing
        FloatVar(
            (Store,),
            model.inner,
        )
    else
        lb_, ub_ = _sanitise_bounds(lb, ub, Int32)
        IntVar(
            (Store, jint, jint),
            model.inner,
            lb_,
            ub_,
        )
    end

    vindex, cindex = _make_var(model, v, set)
    _info(model, vindex).type = INTEGER
    _info(model, vindex).lb = lb
    _info(model, vindex).ub = ub
    return vindex, cindex
end

function _make_boolvar(model::Optimizer, set::MOI.AbstractScalarSet)
    vindex, cindex = _make_var(model, BoolVar((Store,), model.inner), set)
    _info(model, vindex).type = BINARY
    return vindex, cindex
end

function supports_add_constrained_variable(
    ::Optimizer,
    ::Type{F},
) where {
    F <: Union{
        MOI.EqualTo{Float64},
        MOI.LessThan{Float64},
        MOI.GreaterThan{Float64},
        MOI.Interval{Float64},
        MOI.EqualTo{Int},
        MOI.LessThan{Int},
        MOI.GreaterThan{Int},
        MOI.Interval{Int},
        MOI.ZeroOne,
        MOI.Integer,
    },
}
    return true
end

function MOI.add_variable(model::Optimizer)
    v = FloatVar((Store,), model.inner)
    vindex = _make_var(model, v)
    _info(model, vindex).type = CONTINUOUS
    _info(model, vindex).lb = lb
    _info(model, vindex).ub = ub
    return vindex
end


function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.GreaterThan{T},
) where {T <: Real}
    return _make_floatvar(model, set, lb=set.lower)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.LessThan{T},
) where {T <: Real}
    return _make_floatvar(model, set, lb=set.upper)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.EqualTo{T},
) where {T <: Real}
    return _make_floatvar(model, set, lb=set.value, ub=set.value)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.Interval{T},
) where {T <: Real}
    return _make_floatvar(model, set, lb=set.lower, ub=set.upper)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.GreaterThan{T},
) where {T <: Integer}
    return _make_intvar(model, set, lb=set.lower)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.LessThan{T},
) where {T <: Integer}
    return _make_intvar(model, set, lb=set.upper)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.EqualTo{T},
) where {T <: Integer}
    return _make_intvar(model, set, lb=set.value, ub=set.value)
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.Interval{T},
) where {T <: Integer}
    return _make_intvar(model, set, lb=set.lower, ub=set.upper)
end

function MOI.add_constrained_variable(model::Optimizer, set::MOI.ZeroOne)
    return _make_boolvar(model, set)
end

function MOI.add_constrained_variable(model::Optimizer, set::MOI.Integer)
    return _make_intvar(model, set)
end

function MOI.is_valid(model::Optimizer, v::MOI.VariableIndex)
    return haskey(model.variable_info, v)
end

# No deletion allowed.
