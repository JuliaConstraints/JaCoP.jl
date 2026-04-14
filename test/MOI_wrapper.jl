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
            MOI.DualStatus,
            MOI.ConstraintDual,
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
            # BridgeRequiresFiniteDomainError with IntegerToZeroOneBridge
            "test_solve_ObjectiveBound_MAX_SENSE_IP",
            "test_solve_ObjectiveBound_MIN_SENSE_IP",
            "test_variable_solve_Integer_with_lower_bound",
            "test_variable_solve_Integer_with_upper_bound",
            # JaCoP does not support dual values
            "test_DualObjectiveValue_Max_ScalarAffine_LessThan",
            "test_DualObjectiveValue_Max_VariableIndex_LessThan",
            "test_DualObjectiveValue_Min_ScalarAffine_GreaterThan",
            "test_DualObjectiveValue_Min_VariableIndex_GreaterThan",
            # Conic tests: wrong results
            "test_conic_NormInfinityCone_3",
            "test_conic_NormInfinityCone_VectorAffineFunction",
            "test_conic_NormInfinityCone_VectorOfVariables",
            "test_conic_NormOneCone",
            "test_conic_NormOneCone_VectorAffineFunction",
            "test_conic_NormOneCone_VectorOfVariables",
            "test_conic_linear_VectorAffineFunction",
            "test_conic_linear_VectorOfVariables",
            # Constraint tests
            "test_constraint_ScalarAffineFunction_Interval",
            "test_constraint_ScalarAffineFunction_LessThan",
            "test_constraint_ScalarAffineFunction_duplicate",
            "test_constraint_VectorAffineFunction_duplicate",
            "test_constraint_ZeroOne_bounds",
            # CP-SAT tests
            "test_cpsat_BinPacking",
            "test_cpsat_Circuit",
            "test_cpsat_CountAtLeast",
            "test_cpsat_CountBelongs",
            "test_cpsat_CountDistinct",
            "test_cpsat_CountGreaterThan",
            "test_cpsat_ReifiedAllDifferent",
            "test_cpsat_Table",
            # Linear tests
            "test_linear_DUAL_INFEASIBLE",
            "test_linear_HyperRectangle_VectorAffineFunction",
            "test_linear_HyperRectangle_VectorOfVariables",
            "test_linear_Indicator_ON_ONE",
            "test_linear_Indicator_ON_ZERO",
            "test_linear_Indicator_constant_term",
            "test_linear_Indicator_integration",
            "test_linear_LessThan_and_GreaterThan",
            "test_linear_Semicontinuous_integration",
            "test_linear_Semiinteger_integration",
            "test_linear_VariablePrimalStart_partial",
            "test_linear_VectorAffineFunction",
            "test_linear_VectorAffineFunction_empty_row",
            "test_linear_add_constraints",
            "test_linear_integer_integration",
            "test_linear_integer_knapsack",
            "test_linear_integer_solve_twice",
            "test_linear_integration",
            "test_linear_integration_Interval",
            "test_linear_integration_modification",
            "test_linear_modify_GreaterThan_and_LessThan_constraints",
            "test_linear_open_intervals",
            "test_linear_transform",
            "test_linear_variable_open_intervals",
            "test_conic_linear_INFEASIBLE_2",
            "test_linear_SOS1_integration",
            "test_linear_SOS2_integration",
            "test_modification_affine_deletion_edge_cases",
            "test_modification_coef_scalaraffine_lessthan",
            "test_modification_const_vectoraffine_nonpos",
            "test_modification_func_scalaraffine_lessthan",
            "test_modification_multirow_vectoraffine_nonpos",
            "test_modification_set_scalaraffine_lessthan",
            "test_solve_ObjectiveBound_MAX_SENSE_LP",
            "test_solve_ObjectiveBound_MIN_SENSE_LP",
            "test_solve_SOS2_add_and_delete",
            "test_solve_TerminationStatus_DUAL_INFEASIBLE",
            "test_solve_result_index",
            "test_variable_solve_ZeroOne_with_0_upper_bound",
            "test_variable_solve_ZeroOne_with_1_lower_bound",
            "test_variable_solve_ZeroOne_with_upper_bound",
            "test_variable_solve_with_lowerbound",
            "test_variable_solve_with_upperbound",
        ],
    )
    return
end

end  # module

TestJaCoP.runtests()
