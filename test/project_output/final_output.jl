####################################################################################################
# Produces required plots for each scenario with appropriate lambda values over a long simulation ##
####################################################################################################

include("../../src/discrete_event_simulation_project.jl")
function results(max_time)
    scenarios = get_scenarios()

    #plot_simulation_summary(scenarios[1], 
    #                        max_time = max_time,
    #                        lambda_range = LinRange(0.1, 5, 20),
    #                        scenario_label = "scenario 1",
    #                        save_folder = "test/project_output/scenario_1")

    #plot_simulation_summary(scenarios[2], 
    #                        max_time = max_time,
    #                        lambda_range = LinRange(0.1, 5, 20),
    #                        scenario_label = "scenario 2",
    #                        save_folder = "test/project_output/scenario_2")

    #plot_simulation_summary(scenarios[3], 
    #                        max_time = max_time,
    #                        lambda_range = LinRange(0.1, 10, 20),
    #                        scenario_label = "scenario 3",
    #                        save_folder = "test/project_output/scenario_3")

    plot_simulation_summary(scenarios[4], 
                            max_time = max_time,
                            lambda_range = LinRange(0.1, 0.95, 20),
                            scenario_label = "scenario 4",
                            save_folder = "test/project_output/scenario_4")

    #plot_simulation_summary(scenarios[5], 
    #                        max_time = max_time,
    #                        lambda_range = LinRange(0.1, 10, 20),
    #                        scenario_label = "scenario 5",
    #                        save_folder = "test/project_output/scenario_5")
    
end

results(10^7)