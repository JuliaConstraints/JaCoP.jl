using JaCoP
using MathOptInterface
using ConstraintProgrammingExtensions

using Test

const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges
const CP = ConstraintProgrammingExtensions
const COIT = CP.Test

@testset "JaCoP" begin
    include("MOI.jl")
end
