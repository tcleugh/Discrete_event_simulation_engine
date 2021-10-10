using Plots
include("scenarios.jl")

"""
Plots the mean number of items in the total system as a function of λ for the given scenario.
"""
function plot_mean_items(scenario, lambda_range)

end

"""
Plots the proportion of jobs that are in orbit (circulating between nodes) as a function of λ. for the given scenario.
"""
function plot_proportion_in_orbit(scenario, lambda_range)

end

"""
Plots the empirical distribution of the sojourn time of a job through the system (varied as a function of λ). for the given scenario.
"""
function plot_empirical_distribution(scenario, lambda_range)

end

lambda_range = 1:10 # Set here (needs to change)

for scenario in get_scenarios()
    plot_mean_items(scenario, lambda_range)
    plot_proportion_in_orbit(scenario, lambda_range)
    plot_empirical_distribution(scenario, lambda_range)
end
