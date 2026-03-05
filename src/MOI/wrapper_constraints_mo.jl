## ScalarAffineFunction-in-Set

function _build_linear_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.AbstractScalarSet,
    rel::String,
) where {T <: Real}
    coeffs, vars, constant = _parse_to_coeffs_vars(model, f)
    rhs = MOI.constant(s) - constant
    if all(v -> v isa IntVar, vars)
        return LinearInt(
            (Store, Vector{IntVar}, Vector{jint}, JString, jint),
            model.inner,
            vars,
            coeffs,
            rel,
            Int32(rhs),
        )
    elseif all(v -> v isa FloatVar, vars)
        f_canon = MOI.Utilities.canonical(f)
        coeffs_float = Float64[t.coefficient for t in f_canon.terms]
        rhs_float = Float64(MOI.constant(s) - f_canon.constant)
        return LinearFloat(
            (Store, Vector{FloatVar}, Vector{jdouble}, JString, jdouble),
            model.inner,
            vars,
            coeffs_float,
            rel,
            rhs_float,
        )
    else
        error(
            "ScalarAffineFunction with mixed integer and continuous variables is not supported",
        )
    end
end

function _build_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.GreaterThan{T},
) where {T <: Real}
    return _build_linear_constraint(model, f, s, ">=")
end

function _build_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.LessThan{T},
) where {T <: Real}
    return _build_linear_constraint(model, f, s, "<=")
end

function _build_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
    s::MOI.EqualTo{T},
) where {T <: Real}
    return _build_linear_constraint(model, f, s, "==")
end

# No vector of constraints, there is no more efficient way to do it.
# No intervals.
# No constraint deletion.

## VectorOfVariables-in-SOS{I|II}
# Not available. Bridge it?

## VectorOfVariables-in-SecondOrderCone
# Not available.
# https://github.com/radsz/jacop/blob/9c206884e4501c5278ce588233bd171e107bd3c6/src/main/java/org/jacop/fz/constraints/ConstraintFncs.java#L359
