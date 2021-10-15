mutable struct NetworkState <: State
    queues::Vector{Int} #A vector which indicates the number of customers in each queue
    in_transit::Int
    left_system::Int
    params::NetworkParameters #The parameters of the tandem queueing system
end

"""
Constructs an initilized network state from the given parameters
"""
NetworkState(params::NetworkParameters) = NetworkState(fill(0, params.L), # Initial queues
                                                      0,                  # Intial transit
                                                      0,                  # Initial left
                                                      params)

"""
Constructs an initilized network state from the given parameters and altered λ
"""
NetworkState(params::NetworkParameters, λ::Real) = NetworkState(fill(0, params.L), # Initial queues
                                                                0,                 # Intial transit
                                                                0,                 # Initital left
                                                                NetworkParameters(params, λ = convert(Float64, λ)))



""" Returns the total number of jobs in all queues of the system """
queued_count(state::NetworkState)::Int = sum(state.queues)

""" Returns the total number of in transit between queues in the system """
transit_count(state::NetworkState)::Int = state.in_transit

""" Returns the number of jobs in the given queue """
num_in_queue(q::Int, state::NetworkState)::Int = state.queues[q]

""" Prints the current state of the system"""
function show(io::IO, state::NetworkState)
    print(io, "State:\n")
    for (i, queue) in enumerate(state.queues)
        print(io, "Q$i: $queue\n")
    end
    print(io, "T: $(state.in_transit)\n")
end

function new_job(q::Int, time::Float64, state::NetworkState)
    state.queues[q] += 1
end

function new_transit(time::Float64, transit_time::Float64, state::NetworkState)
    state.in_transit += 1
end

function pop_queue(q::Int, time::Float64, state::NetworkState)
    state.queues[q] -= 1
    state.left_system += 1
end

function queue_to_transit(q::Int, time::Float64, transit_time::Float64, state::NetworkState)
    state.queues[q] -= 1
    state.in_transit += 1
end

function pop_transit(time::Float64, state::NetworkState)
    state.in_transit -= 1
    state.left_system += 1
end

function transit_to_queue(q::Int, time::Float64, state::NetworkState)
    state.in_transit -= 1
    state.queues[q] += 1
end

update_transit(time::Float64, transit_time::Float64, state::NetworkState) = nothing

function failed_arrival(time::Float64, state::NetworkState) 
    state.left_system += 1
end