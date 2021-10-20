using Parameters, LinearAlgebra, DataStructures, Plots, Distributions, Random, StatsBase
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

#run_default_sims(lambda_range = 1:0.1:5, max_time = 10^5)
#run_tracking_sim(get_scenarios()[1], 3)
#run_default_no_tracking(lambda_range = 1:0.5:5, max_time = 10^7)