# Instructions for running the simulation 

**There** are many files and many functions defined throughout the repository. Below, we will give you some basic informaiton on different ways that you can run the simulations and see what is happening. 

__However__, for everything to work properly, please first run the file discrete_event_simulation_project.jl so that all functions / methods are loaded. 

### Option 1 -> run_default_sims() 

This function by the name of 
'''
run_default_sims()
'''
will generate all five scenarios, simulate each one in order (1-5), and plot all three required summary plots. You are able to make use of two optional inputs: lambda_range and max_time. For max_time, it defaults to $10^4$ however larger times are fine to use. The lambda_range defaults to $1:5$ but you can also specify your own range, for example $1:0.2:5$ .

### Option 2 -> run_tracking_sim(scenario, $\lambda$; ... )

This function by the name of 
'''
run_tracking_sim()
'''
will print out the full state of the system - essentially what happens, when and where. The main inputs of scenario and $\lambda$ take in the specific scenario you want to run (eg third) and $\lambda$ value (eg 2.5). The output will show numbers corresponding to queue number, and letters for what event took place. Here is an example of running it with the values mentioned:
'''
run_tracking_sim(get_scenarios()[3], 2.5)
'''