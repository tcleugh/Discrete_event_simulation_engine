# Thomas-Cleugh-and-Jason-Jones-2504-2021-PROJECT2

## Discrete Event Simulation

In this project, we are simulating a complex queueing network model, with motivation coming from a typical amusement park setup (eg MovieWorld). 

If you are interested, you can read about the in-depth description [here](https://courses.smp.uq.edu.au/MATH2504/assessment_html/project2.html)

# Instructions for running the simulation 

**There** are many files and many functions defined throughout the repository. Below, we will give you some basic informaiton on different ways that you can run the simulations and see what is happening. 

To produce the project plots over the long horizon, run the file named final_output.jl (note: this will take a LONG time). To produce similar plots over a much shorter time span, run the exploratory_plots.jl file. Finally, for specific / custom simulations, please read on to the below options. 

__However__, for everything to work properly, please first run the file discrete_event_simulation_project.jl so that all functions / methods are loaded. 

### Option 1 -> run_default_sims() 

This function by the name of 
```
run_default_sims()
```
will generate all five scenarios, simulate each one in order (1-5), and plot all three required summary plots. You are able to make use of two optional inputs: lambda_range and max_time. For max_time, it defaults to 10^4 however larger times are fine to use. The lambda_range defaults to 1:5 but you can also specify your own range, for example 1:0.2:5.

### Option 2 -> run_tracking_sim(scenario, lambda; ... )

This function by the name of 
```
run_tracking_sim()
```
will print out the full state of the system - essentially what happens, when and where. The main inputs of scenario and lambda take in the specific scenario you want to run (eg third) and lambda value (eg 2.5). The output will show numbers corresponding to queue number, and letters for what event took place. Here is an example of running it with the values mentioned:
```
run_tracking_sim(get_scenarios()[3], 2.5)
```

### Option 3 -> run_default_no_tracking()

This function by the name of 
```
run_default_no_tracking()
```
is very similar to the default simulation runner, however the state only keeps track of queue and transit totals. It will then output the first two summary plots (mean, proportion), but not the distribution. You can again specify your own max_time and lambda_range as optional arguments. 

### Option 4 -> plot_simulation_summary(scenario, ...)

This function by the name of 
```
plot_simulation_summary()
```
is the main function used inside of run_default_sims() and can be used by itself. It is setup to output all three required summary plots (mean, proportion, cdf) by specifying the single scenario you wish to investigate. As before, you can input a selected lambda_range and max_time, but additionally you can input a scenario_label (as a string). This is mainly used for running all scenarios at once to place the right label at each iteration.  