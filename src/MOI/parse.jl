function _parse_to_vars(
    model::Optimizer,
    f::MOI.VectorOfVariables,
)
    return [_info(model, v) for v in f.variables]
end

function _parse_to_coeffs_vars(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{T},
) where {T <: Real}
    f = MOI.Utilities.canonical(f)
    coeffs, vars = _parse_to_coeffs_vars(model, f.terms)
    return coeffs, vars, f.constant
end

function _parse_to_coeffs_vars(
    model::Optimizer,
    terms::Vector{MOI.ScalarAffineTerm{T}},
) where {T <: Integer}
    coeffs = Int32[t.coefficient for t in terms]
    vars = Variable[_info(model, t.variable) for t in terms]
    return coeffs, vars
end
