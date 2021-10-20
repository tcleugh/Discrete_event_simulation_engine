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
                                    Q = diagm(3=>0.8*ones(17), -17=>ones(3)), # changed from Yoni's advice                            
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
                                                lambda_range = 1.0:5.0,
                                                save_folder::Union{Symbol, String} = :none)

    mean_jobs, proportions, all_durations = Float64[], Float64[], Vector{Float64}[]

    for λ in lambda_range
        prev_time, prev_total, prev_transit = 0.0, 0.0, 0.0
        total_integral, transit_integral = 0.0, 0.0 
        durations = Float64[]

        function record(time::Float64, state::TrackedState) 
            time_diff = time - prev_time
            total_integral += prev_total * time_diff
            transit_integral += prev_transit * time_diff
            
            prev_time = time
            prev_total = total_count(state)
            prev_transit = transit_count(state)

            while length(state.left_system) > 0
                job = pop!(state.left_system)
                push!(durations, duration(job))
            end
            return nothing
        end

        Random.seed!(0)
        simulate(NetworkParameters(scenario, λ), 
                job_tracking = :times, 
                max_time = max_time, 
                call_back = record)

        push!(mean_jobs, total_integral / max_time)
        push!(proportions, (transit_integral / total_integral))
        push!(all_durations, durations)
    end    

    p1 = plot(lambda_range, mean_jobs, 
                    title = "Mean number of jobs in system $scenario_label", 
                    xlabel = "λ (mean arrival rate)", 
                    ylabel = "Mean num jobs", 
                    label = false)
    if save_folder != :none
        savefig(p1, save_folder * "/mean $(scenario_label).png")
    end
    display(p1)

    p2= plot(lambda_range, proportions, 
                    title = "Proportion of jobs in orbit $scenario_label", 
                    xlabel = "λ (mean arrival rate)", 
                    ylabel = "Proportion", 
                    label = false)
    if save_folder != :none
        savefig(p2, save_folder * "/proportion $(scenario_label).png")
    end
    display(p2)


    p3 = plot(title = "Empirical CDF of sojurn time $scenario_label", xlabel = "Duration", ylabel = "Probability")
    times = 0:0.01:max_time
    for i in LinRange(1, length(lambda_range), 5)
        index = convert(Int, floor(i))
        n = length(all_durations[index])
        #plot!(sort(all_durations[index]), (1:n)./n, label = "λ = $(lambda_range[index])")
        plot!(sort(all_durations[index])[convert.(Int, floor.(LinRange(1,n, 100)))], 1:100, label = "λ = $(round(lambda_range[index], 2))")
    end
    if save_folder != :none
        savefig(p3, save_folder * "/ecdf $(scenario_label).png")
    end
    display(p3)

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
function run_tracking_sim(scenario::NetworkParameters, λ::Real; 
                            max_time::Float64 = 10.0, 
                            log_times::Vector{Float64} = [max_time - 10.0^(-10)])
    
        Random.seed!(0)
        simulate(NetworkParameters(scenario, λ),  
                job_tracking = :full, 
                max_time = max_time, 
                call_back = (time, state) -> nothing,
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
            prev_time, prev_total, prev_transit = 0.0, 0.0, 0.0
            total_integral, transit_integral = 0.0, 0.0 
    
            function record(time::Float64, state::NetworkState) 
                time_diff = time - prev_time
                total_integral += prev_total * time_diff
                transit_integral += prev_transit * time_diff
                
                prev_time = time
                prev_total = total_count(state)
                prev_transit = transit_count(state)
                return nothing
            end
    
            Random.seed!(0)
            simulate(NetworkParameters(scenario, λ),  
                    job_tracking = :none, 
                    max_time = max_time, 
                    call_back = record)
    
            push!(mean_jobs, total_integral / max_time)
            push!(proportions, (transit_integral / total_integral))
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