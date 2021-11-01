## ScalarAffineFunction-in-Set

function _build_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.GreaterThan{T},
) where {T <: Real}
    coeffs, vars, constant = _parse_to_coeffs_vars(model, f)
    return LinearInt(model.inner, coeffs, vars, ">=", s.constant - constant)
end

function _build_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.LessThan{T},
) where {T <: Real}
    coeffs, vars, constant = _parse_to_coeffs_vars(model, f)
    return LinearInt(model.inner, coeffs, vars, "<=", s.constant - constant)
end

function _build_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.EqualTo{T},
) where {T <: Real}
    coeffs, vars, constant = _parse_to_coeffs_vars(model, f)
    return LinearInt(model.inner, coeffs, vars, "==", s.constant - constant)
end

# No vector of constraints, there is no more efficient way to do it.
# No intervals.
# No constraint deletion.

## VectorOfVariables-in-SOS{I|II}
# Not available. Bridge it?

## VectorOfVariables-in-SecondOrderCone
# Not available.
# https://github.com/radsz/jacop/blob/9c206884e4501c5278ce588233bd171e107bd3c6/src/main/java/org/jacop/fz/constraints/ConstraintFncs.java#L359
