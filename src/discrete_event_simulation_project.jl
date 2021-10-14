using Parameters, LinearAlgebra, DataStructures, Plots, Distributions

include("event.jl")
    include("state/state.jl")
    include("state/total_state.jl")
    include("state/job.jl")
    include("state/tracked_state.jl")
include("simulation.jl")

include("output.jl")

run_default_sims()
run_tracking_sim(get_scenarios()[1], 2.0, full_history = true)
run_default_no_tracking()