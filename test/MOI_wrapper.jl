module TestJaCoP

using Test
import MathOptInterface as MOI
import JaCoP

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_runtests()
    model = MOI.instantiate(
        JaCoP.Optimizer,
        with_bridge_type = Float64,
        with_cache_type = Float64,
    )
    config = MOI.Test.Config(
        atol = 1e-6,
        exclude = Any[
            MOI.ConstraintBasisStatus,
            MOI.VariableBasisStatus,
            MOI.ConstraintName,
            MOI.VariableName,
            MOI.RawStatusString,
            MOI.SolveTimeSec,
            MOI.SolverVersion,
            MOI.delete, # segfaults
        ],
    )
    MOI.Test.runtests(
        model,
        config;
        verbose = true,
        exclude = [
            # MathOptInterface.Bridges.BridgeRequiresFiniteDomainError{MathOptInterface.Bridges.Constraint.IntegerToZeroOneBridge{Float64}, MathOptInterface.VariableIndex}:
            "test_solve_ObjectiveBound_MAX_SENSE_IP",
            "test_solve_ObjectiveBound_MIN_SENSE_IP",
            "test_variable_solve_Integer_with_lower_bound",
            "test_variable_solve_Integer_with_upper_bound",
        ],
    )
    return
end

end  # module

TestJaCoP.runtests()
