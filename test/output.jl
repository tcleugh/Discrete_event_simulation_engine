"""
Returns a vector of default scenarios for output.
"""
function get_scenarios()::Vector{NetworkParameters}

    scenario1 = NetworkParameters(  L=3, 
                                    gamma_scv = 3.0, 
                                    λ = NaN, 
                                    η = 4.0, 
                                    μ_vector = ones(3),
                                    P = [0 1.0 0;
                                        0 0 1.0;
                                        0 0 0],
                                    Q = zeros(3,3),
                                    p_e = [1.0, 0, 0],
                                    K = fill(5,3))

    scenario2 = NetworkParameters(  L=3, 
                                    gamma_scv = 3.0, 
                                    λ = NaN, 
                                    η = 4.0, 
                                    μ_vector = ones(3),
                                    P = [0 1.0 0;
                                        0 0 1.0;
                                        0.5 0 0],
                                    Q = zeros(3,3),
                                    p_e = [1.0, 0, 0],
                                    K = fill(5,3))

    scenario3 = NetworkParameters(  L=3, 
                                    gamma_scv = 3.0, 
                                    λ = NaN, 
                                    η = 4.0, 
                                    μ_vector = ones(3),
                                    P = [0 1.0 0;
                                        0 0 1.0;
                                        0.5 0 0],
                                    Q = [0 0.5 0;
                                        0 0 0.5;
                                        0.5 0 0],
                                    p_e = [1.0, 0, 0],
                                    K = fill(5,3))

    scenario4 = NetworkParameters(  L=5, 
                                    gamma_scv = 3.0, 
                                    λ = NaN, 
                                    η = 4.0, 
                                    μ_vector = collect(5:-1:1),
                                    P = [0   0.5 0.5 0   0;
                                        0   0   0   1   0;
                                        0   0   0   0   1;
                                        0.5 0   0   0   0;
                                        0.2 0.2 0.2 0.2 0.2],
                                    Q = [0 0 0 0 0;
                                        1 0 0 0 0;
                                        1 0 0 0 0;
                                        1 0 0 0 0;
                                        1 0 0 0 0],                             
                                    p_e = [0.2, 0.2, 0, 0, 0.6],
                                    K = [-1, -1, 10, 10, 10])

    scenario5 = NetworkParameters(  L=20, 
                                    gamma_scv = 3.0, 
                                    λ = NaN, 
                                    η = 4.0, 
                                    μ_vector = ones(20),
                                    P = zeros(20,20),
                                    Q = diagm(3=>ones(19), -19=>ones(3)),                             
                                    p_e = vcat(1, zeros(19)),
                                    K = fill(5,20))

    return [scenario1, scenario2, scenario3, scenario4, scenario5]
end

"""
Plots the mean number of items in the total system and the proportion of jobs that are in orbit (circulating between nodes)
as a function of λ for the given scenario.
"""
function plot_mean_and_proportion(scenario::NetworkParameters;
                            max_time::Float64 = 10.0^7,
                            scenario_label::String = "",
                            lambda_range = 1.0:5.0)

    mean_jobs, proportions = Float64[], Float64[]


    for λ in lambda_range 
        # was hard-coded as int range -> throws errors with isolated usage

        in_queue, in_transit = Int[], Int[]

        function record(time::Float64, state::NetworkState) 
            #println("time = $time, $(state.queues)")
            #push!(time_traj, time)
            push!(in_queue, sum(state.queues))
            push!(in_transit, state.in_transit)
            return nothing
        end

        init_state = NetworkState(scenario, λ)

        simulate(init_state, max_time = max_time, call_back = record)

        total_in_system = sum(in_queue) + sum(in_transit)

        push!(mean_jobs,  total_in_system / length(in_queue))
        push!(proportions, sum(in_transit) / total_in_system)
        
    end    
    
    display(plot(lambda_range, mean_jobs, 
                    title = "Mean number of jobs in system $scenario_label", 
                    xlabel = "λ", 
                    ylabel = "Mean num jobs", 
                    label = false))

    display(plot(lambda_range, proportions, 
                    title = "Proportion of jobs in orbit $scenario_label", 
                    xlabel = "λ", 
                    ylabel = "Proportion", 
                    label = false))  

end


"""
Plots the empirical distribution of the sojourn time of a job through the system (varied as a function of λ). for the given scenario.
"""
function plot_empirical_distribution(scenario::NetworkParameters;
                                        max_time::Float64 = 10.0^7,
                                        scenario_label::String = "",
                                        lambda_range = 1.0:5.0)

    all_durations = Vector{Float64}[]

    for λ in lambda_range

        durations = Float64[]

        function record_durations(time::Float64, state::TrackedNetworkState) 
            while length(state.left_system) > 0
                job = pop!(state.left_system)
                push!(durations, job.exit_time - job.entry_time)
            end
            return nothing
        end

        init_state = TrackedNetworkState(scenario, λ)

        simulate(init_state, max_time = max_time, call_back = record_durations)
        
        push!(all_durations, durations)
    end    
    
    p = plot(title = "Empirical CDF of sojurn time $scenario_label", xlabel = "Duration", ylabel = "Probability")
    for i in 1:length(lambda_range)
        n = length(all_durations[i])
        plot!(sort(all_durations[i]), (1:n)./n, label = "λ = $(lambda_range[i])")
    end
    display(p)

end

"""
One master function to cycle through each scenario with specified lambda's 
    Only critique is that each function is setup to run its own simulation -> not sure if 
    that has any effect on results 
"""

function run_default_sims()

    lambda_range = 0.1:0.1:5
    simulation_time = 10.0^5

    for (i, scenario) in enumerate(get_scenarios()[1:4])
        plot_mean_and_proportion(scenario, 
                                 max_time = simulation_time,
                                 lambda_range = lambda_range,
                                 scenario_label = "scenario $i"
                                 )

        plot_empirical_distribution(scenario, 
                                    max_time = simulation_time, 
                                    lambda_range = 1.0:10.0, 
                                    scenario_label = "scenario $i"
                                    )
    end
    
end

