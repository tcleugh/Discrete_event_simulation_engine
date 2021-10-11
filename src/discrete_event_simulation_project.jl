using Parameters, LinearAlgebra, DataStructures, Plots, Distributions, StatsPlots

include("event.jl")
include("state.jl")
include("helper_functions.jl")
include("simulation.jl")
include("simulation_tracked.jl")
include("output.jl")

run_default_sims()