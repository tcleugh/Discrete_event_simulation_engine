###################################################################
## Used to determine lambda values of interest for each scenario ##
###################################################################

include("../../src/discrete_event_simulation_project.jl")
function test_lambda_range(scenario_num, lambda_range, max_time)
    scenario = get_scenarios()[scenario_num]
        plot_simulation_summary(scenario, 
                                     max_time = max_time,
                                     lambda_range = lambda_range,
                                     scenario_label = "scenario $scenario_num",
                                     save_folder = "test/testing_plots/scenario_$scenario_num")
end

test_lambda_range(1, 0.1:20, 10^4)
test_lambda_range(2, 0.1:20, 10^4)
test_lambda_range(3, 0.1:20, 10^4)
test_lambda_range(4, 0.1:20, 10^4)
test_lambda_range(5, 0.1:20, 10^4)