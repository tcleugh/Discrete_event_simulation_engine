using Parameters, LinearAlgebra, DataStructures, Plots, Distributions, Random
import Base: push!, isless, show

include("event.jl")
    include("state/state.jl")
        include("state/totals/total_state.jl")
        include("state/tracking/job.jl")
        include("state/tracking/tracked_state.jl")
        include("state/full_tracking/full_job.jl")
        include("state/full_tracking/full_tracked_state.jl")
include("simulation.jl")
include("output.jl")

run_default_sims(lambda_range = 0.1:0.1:5, max_time = 10^4)
#run_tracking_sim(get_scenarios()[1], 2.0, full_history = true)
#run_default_no_tracking(lambda_range = 1:1:5, max_time = 10^6)