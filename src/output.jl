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
                                    p_e = vcat(1,zeros(19)),
                                    K = fill(5,20))

    return [scenario1, scenario2, scenario3, scenario4, scenario5]
end

"""
Plots the mean number of items in the total system as a function of λ for the given scenario.
"""
function plot_mean_items(scenario::NetworkParameters)
    
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

"""
Plots the proportion of jobs that are in orbit (circulating between nodes) as a function of λ. for the given scenario.
"""
function plot_proportion_in_orbit(scenario::NetworkParameters, lambda_range)

end

"""
Plots the empirical distribution of the sojourn time of a job through the system (varied as a function of λ). for the given scenario.
"""
function plot_empirical_distribution(scenario::NetworkParameters, lambda_range)

end

function run_default_sims()
    #lambda_range = 1:10 # Set here (needs to change)

    for scenario in get_scenarios()
        plot_mean_items(scenario)
    #    plot_proportion_in_orbit(scenario, lambda_range)
    #    plot_empirical_distribution(scenario, lambda_range)
    end
end