using Parameters, LinearAlgebra, DataStructures, Plots, Distributions
import Base: push!, isless, show

include("event.jl")
    include("state/state.jl")
    include("state/total_state.jl")
    include("state/job.jl")
    include("state/tracked_state.jl")
include("simulation.jl")

include("output.jl")

run_default_sims(lambda_range = 0.1:0.1:5, max_time = 10^4)
run_tracking_sim(get_scenarios()[1], 2.0, full_history = true)
#run_default_no_tracking(lambda_range = 1:1:5, max_time = 10^6)