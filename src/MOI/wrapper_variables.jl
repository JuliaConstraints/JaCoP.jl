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
        if lb === nothing
            lb = typemin(Float64)
        end
        if ub === nothing
            ub = typemax(Float64)
        end

        FloatVar(
            (Store, jdouble, jdouble),
            model.inner,
            lb,
            ub,
        )
    end
    return _make_var(model, v, set)
end

function _make_intvar(
    model::Optimizer,
    set::MOI.AbstractScalarSet;
    lb::Int32=typemin(Int),
    ub::Int32=typemax(Int),
)
    v = if lb === nothing && ub === nothing
        FloatVar(
            (Store,),
            model.inner,
        )
    else
        if lb === nothing
            lb = typemin(Int)
        end
        if ub === nothing
            ub = typemax(Int)
        end
        
        IntVar(
            (Store, jdouble, jdouble),
            model.inner,
            lb,
            ub,
        )
    end
    vindex, cindex = _make_var(model, v, set)
    _info(model, vindex).type = INTEGER
    return vindex, cindex
end

function _make_boolvar(model::Optimizer, set::MOI.AbstractScalarSet)
    vindex, cindex = _make_var(model, BoolVar((Store,), model.inner), set)
    _info(model, vindex).type = BINARY
    return vindex, cindex
end
