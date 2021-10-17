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

# function made to hold all scenarios
tester = get_scenarios();

# some variables 
#total_time = 10.0^5;
#lamb_vals = 1.0:5.0 ;

# seeing how the individual parts work
#plot_mean_and_proportion(tester[1], max_time=total_time, lambda_range=lamb_vals, scenario_label="first scenario")

#plot_empirical_distribution(tester[1], max_time=total_time, lambda_range=lamb_vals, scenario_label="first scenario")

# new changes 
run_default_sims(lambda_range = 1:0.5:5, max_time = 10^5)
#run_tracking_sim(get_scenarios()[1], 3)
#run_default_no_tracking(lambda_range = 1:0.5:5, max_time = 10^5)

"""
I changed the creation of the overflow matrix in scenario5 and tested it separately
"""
#fifth_scen = tester[5];

#plot_simulation_summary(fifth_scen, max_time = 10^5, scenario_label = "testing Fifth scenario")
