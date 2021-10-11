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
                            lambda_range = 1:5)

    mean_jobs, proportions = Float64[], Float64[]


    for λ in lambda_range

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

















####### Not relevant #############
function do_plots(scenario::NetworkParameters)
    max_time = 100.0
    time_traj, queues_traj, in_transit_traj = Float64[], Vector{Int}[], Int[]

    function record_traj(time::Float64, state::NetworkState) 
        #println("time = $time, $(state.queues)")
        push!(time_traj, time)
        push!(queues_traj, copy(state.queues))
        push!(in_transit_traj, state.in_transit)
        return nothing
    end

    λi = 1
    params = NetworkParameters(L = scenario.L, 
                               gamma_scv = scenario.gamma_scv, 
                               λ = λi,
                               η = scenario.η,
                               μ_vector = copy(scenario.μ_vector),
                               P = copy(scenario.P),
                               Q = copy(scenario.Q),
                               p_e = copy(scenario.p_e),
                               K = copy(scenario.K)
    )

    simulate(params, max_time = max_time, call_back = record_traj)
    total_queues = map(q_vector -> sum(q_vector), queues_traj)
    
    display(plot(time_traj, in_transit_traj, title = "Number of jobs in transit", xlabel = "Time", ylabel = "Num jobs between queues"))
    display(plot(time_traj, total_queues, title = "Total number of jobs in queues", xlabel = "Time", ylabel = "Total in queues"))
    
    p = plot(title = "Number of jobs in each queue", xlabel = "Time", ylabel = "Jobs in queue")
    for i in 1:params.L
        queue_counts = map(queues -> queues[i], queues_traj)
        plot!(time_traj, queue_counts, label = "Queue $i")
    end
    display(p)

    time_traj, queues_traj, in_transit_traj, params
end