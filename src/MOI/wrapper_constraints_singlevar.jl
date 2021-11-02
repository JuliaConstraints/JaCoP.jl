function _has_lb(model::Optimizer, index::MOI.VariableIndex)
    return _info(model, index).lb !== nothing
end
function _has_ub(model::Optimizer, index::MOI.VariableIndex)
    return _info(model, index).ub !== nothing
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex, MOI.LessThan{T}},
) where {T <: Real}
    index = MOI.VariableIndex(c.value)
    return MOI.is_valid(model, index) && _has_ub(model, index)
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex, MOI.GreaterThan{T}},
) where {T <: Real}
    index = MOI.VariableIndex(c.value)
    return MOI.is_valid(model, index) && _has_lb(model, index)
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex, MOI.Interval{T}},
) where {T <: Real}
    index = MOI.VariableIndex(c.value)
    return MOI.is_valid(model, index) &&
           _has_lb(model, index) &&
           _has_ub(model, index)
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex, MOI.EqualTo{T}},
) where {T <: Real}
    index = MOI.VariableIndex(c.value)
    return MOI.is_valid(model, index) &&
           _info(model, index).lb == _info(model, index).ub
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne},
)
    index = MOI.VariableIndex(c.value)
    if !MOI.is_valid(model, index)
        return false
    end

    return _info(model, index).type == BINARY
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex, MOI.Integer},
)
    index = MOI.VariableIndex(c.value)
    if !MOI.is_valid(model, index)
        return false
    end

    return _info(model, index).type == INTEGER
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.VariableIndex, <:Any},
)
    MOI.throw_if_not_valid(model, c)
    return MOI.VariableIndex(MOI.VariableIndex(c.value))
end

function MOI.set(
    ::Optimizer,
    ::MOI.ConstraintFunction,
    ::MOI.ConstraintIndex{MOI.VariableIndex, S},
    ::MOI.VariableIndex,
) where {S}
    throw(MOI.SettingVariableIndexFunctionNotAllowed())
    return
end

# CP.Domain.
function MOI.supports_constraint(
    ::Optimizer,
    ::MOI.VariableIndex,
    ::CP.Domain{T},
) where {T <: Integer}
    return true
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VariableIndex,
    s::CP.Domain{T},
) where {T <: Integer}
    # Add each possible value separately. Same logic as
    # https://github.com/radsz/jacop/blob/develop/src/main/java/org/jacop/fz/VariablesParameters.java#L238-L267
    v = _info(model, f).variable
    for e in s.values
        jcall(v, "addDom", (jint, jint), e, e)
    end

    index = MOI.ConstraintIndex{F, S}(length(model.constraint_info) + 1)
    jacop_add_constraint_to_store(model.inner, constr)
    model.constraint_info[index] = ConstraintInfo(index, nothing, f, s)
    return index
end
