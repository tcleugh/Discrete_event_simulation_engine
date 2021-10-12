using Parameters, LinearAlgebra, DataStructures, Plots, Distributions, StatsPlots

include("event.jl")
include("state.jl")
include("simulation.jl")
include("output.jl")

# function made to hold all scenarios
tester = get_scenarios();

# some variables 
total_time = 10.0^5;
lamb_vals = 1.0:5.0 ;

# seeing how the individual parts work
plot_mean_and_proportion(tester[1], max_time=total_time, lambda_range=lamb_vals, scenario_label="first scenario")

plot_empirical_distribution(tester[1], max_time=total_time, lambda_range=lamb_vals, scenario_label="first scenario")

