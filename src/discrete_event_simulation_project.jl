using Parameters, LinearAlgebra, DataStructures, Plots, Distributions

include("event.jl")
    include("state/state.jl")
    include("state/total_state.jl")
    include("state/tracked_state.jl")
include("simulation.jl")

include("output.jl")

run_default_sims()
