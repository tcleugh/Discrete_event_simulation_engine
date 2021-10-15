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
Runs simulations with varied arrival rate where the state keeps track of jobs locations.
Then plots the mean number of jobs in the system and Proportion of jobs orbiting between queues wrt λ.
Also plots the emprical distribution of the sojurn time of jobs in the system varied by λ.
"""
function plot_simulation_summary(scenario::NetworkParameters;
                                                max_time::Real = 10.0^7,
                                                scenario_label::String = "",
                                                lambda_range = 1.0:5.0)

    mean_jobs, proportions, all_durations = Float64[], Float64[], Vector{Float64}[]

    for λ in lambda_range
        num_calls, running_mean, running_prop, durations = 0, 0, 0, Float64[]

        function record(time::Float64, state::TrackedState) 
            num_calls += 1
            total_in_system = total_count(state)
            running_mean = (running_mean * (num_calls - 1) + total_in_system) / num_calls
            running_prop = (running_prop * (num_calls - 1) + transit_count(state) / max(total_in_system, 1)) / num_calls
            while length(state.left_system) > 0
                job = pop!(state.left_system)
                push!(durations, duration(job))
                end
            return nothing
        end

        simulate(TrackedState(scenario, λ), max_time = max_time, call_back = record)

        push!(mean_jobs, running_mean)
        push!(proportions, running_prop)
        push!(all_durations, durations)
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


    p = plot(title = "Empirical CDF of sojurn time $scenario_label", xlabel = "Duration", ylabel = "Probability")
    for i in LinRange(1, length(lambda_range), 5)
        index = convert(Int, floor(i))
        n = length(all_durations[index])
        plot!(sort(all_durations[index]), (1:n)./n, label = "λ = $(lambda_range[index])")
    end
    display(p)

end

"""
Plots the simulation summarys (see plot_simulation_summary()) of all default scenarios run over a long simulation.
"""
function run_default_sims(;lambda_range = 1.0:5.0, max_time = 10.0^4)

    for (i, scenario) in enumerate(get_scenarios()[1:4])
        plot_simulation_summary(scenario, 
                                     max_time = max_time,
                                     lambda_range = lambda_range,
                                     scenario_label = "scenario $i")
    end
end

"""
Runs a short simulation of the given scenario printing the full state of the system.
"""
function run_tracking_sim(scenario::NetworkParameters, λ::Float64; 
                            max_time::Float64 = 10.0, log_times::Vector{Float64} = [max_time - 10.0^(-10)], full_history::Bool = false)
    simulate(FullTrackedState(scenario, λ), 
                max_time = max_time, 
                call_back = (full_history) ? (time, state) -> nothing : (time, state) -> empty!(state.left_system),
                log_times = log_times)
end


"""
Runs simulations with varied arrival rate where the state only keeps track of queue and transit totals.
Then plots the mean number of jobs in the system and Proportion of jobs orbiting between queues wrt λ.
"""
function run_default_no_tracking(;lambda_range = 1.0:5.0, max_time = 10.0^4)

    for (i, scenario) in enumerate(get_scenarios()[1:4])
        mean_jobs, proportions = Float64[], Float64[]

        for λ in lambda_range
            num_calls, running_mean, running_prop = 0, 0, 0
    
            function record(time::Float64, state::NetworkState) 
                num_calls += 1
                total_in_system = total_count(state)
                running_mean = (running_mean * (num_calls - 1) + total_in_system) / num_calls
                running_prop = (running_prop * (num_calls - 1) + transit_count(state) / max(total_in_system, 1)) / num_calls
                return nothing
            end
    
            simulate(NetworkState(scenario, λ), max_time = max_time, call_back = record, log_times = [max_time - 0.0001])
    
            push!(mean_jobs, running_mean)
            push!(proportions, running_prop)
        end    


        display(plot(lambda_range, mean_jobs, 
                        title = "Mean number of jobs in system scenario $i", 
                        xlabel = "λ", 
                        ylabel = "Mean num jobs", 
                        label = false))

        display(plot(lambda_range, proportions, 
                        title = "Proportion of jobs in orbit scenario $i", 
                        xlabel = "λ", 
                        ylabel = "Proportion", 
                        label = false)) 

    end
end