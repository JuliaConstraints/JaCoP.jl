# Inspired from https://jump.dev/JuMP.jl/stable/tutorials/linear/sudoku/

using JuMP
import JaCoP

@testset "Sudoku" begin
    # The given digits
    init_sol = [
        5 3 0 0 7 0 0 0 0
        6 0 0 1 9 5 0 0 0
        0 9 8 0 0 0 0 6 0
        8 0 0 0 6 0 0 0 3
        4 0 0 8 0 3 0 0 1
        7 0 0 0 2 0 0 0 6
        0 6 0 0 0 0 2 8 0
        0 0 0 4 1 9 0 0 5
        0 0 0 0 8 0 0 7 9
    ]

    model = Model()

    @variable(model, 1 <= x[1:9, 1:9] <= 9, Int);

    # Then, we enforce that the values in each row must be all-different:

    @constraint(model, [i = 1:9], x[i, :] in MOI.AllDifferent(9));

    # That the values in each column must be all-different:

    @constraint(model, [j = 1:9], x[:, j] in MOI.AllDifferent(9));

    # And that the values in each 3x3 sub-grid must be all-different:

    for i in (0, 3, 6), j in (0, 3, 6)
        @constraint(
            model,
            vec(x[i .+ (1:3), j .+ (1:3)]) in MOI.AllDifferent(9)
        )
    end

    # Finally, as before we set the initial solution and optimize:

    for i in 1:9, j in 1:9
        if init_sol[i, j] != 0
            fix(x[i, j], init_sol[i, j]; force=true)
        end
    end

    set_optimizer(model, JaCoP.Optimizer)
    optimize!(model)

    @test JuMP.termination_status(model) == MOI.OPTIMAL
    @test JuMP.primal_status(model) == MOI.FEASIBLE_POINT
    @test JuMP.value.(x) == [
        5 3 4 6 7 8 9 1 2
        6 7 2 1 9 5 3 4 8
        1 9 8 3 4 2 5 6 7
        8 5 9 7 6 1 4 2 3
        4 2 6 8 5 3 7 9 1
        7 1 3 9 2 4 8 5 6
        9 6 1 5 3 7 2 8 4
        2 8 7 4 1 9 6 3 5
        3 4 5 2 8 6 1 7 9
    ]
end
