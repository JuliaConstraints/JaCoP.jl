const CONFIG = MOIT.Config(Int)

const OPTIMIZER = JaCoP.Optimizer()
const BRIDGED_OPTIMIZER = MOI.Bridges.full_bridge_optimizer(OPTIMIZER, Float64)

COIT.runtests(
    BRIDGED_OPTIMIZER,
    CONFIG
)
