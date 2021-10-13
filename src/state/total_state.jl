mutable struct NetworkState <: State
    queues::Vector{Int} #A vector which indicates the number of customers in each queue
    in_transit::Int
    params::NetworkParameters #The parameters of the tandem queueing system
end

"""
Constructs an initilized network state from the given parameters
"""
NetworkState(params::NetworkParameters) = NetworkState(fill(0, params.L), # Initial queues
                                                      0,                 # Intial transit
                                                      params)

"""
Constructs an initilized network state from the given parameters and altered λ
"""
NetworkState(params::NetworkParameters, λ::Real) = NetworkState(fill(0, params.L), # Initial queues
                                                                       0,            # Intial transit
                                                                       NetworkParameters(params, λ = convert(Float64, λ)))



""" Returns the total number of jobs in all queues of the system """
queued_count(state::NetworkState)::Int = sum(state.queues)

""" Returns the total number of in transit between queues in the system """
transit_count(state::NetworkState)::Int = state.in_transit

""" Returns the number of jobs in the given queue """
num_in_queue(q::Int, state::NetworkState)::Int = state.queues[q]

function pop_transit(state::NetworkState)::Int
    state.in_transit -= 1
end

function pop_queue(q::Int, state::NetworkState)::Int
    state.queues[q] -= 1
end

function add_to_queue(q::Int, time::Float64, state::NetworkState; job::Int = 0)::Vector{TimedEvent}
    new_timed_events = TimedEvent[]

    if !is_full(q, state)
        state.queues[q] += 1  #increase number in chosen queue
    
        #if this is the only job on the server engage service
        num_in_queue(q, state) == 1 && push!(new_timed_events,
                                    TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q)))
    else
        #Finds new queue using overflow matrix
        append!(new_timed_events, add_to_transit(q, time, state, overflow = true))
    end

    return new_timed_events
end

function add_to_transit(q::Int, time::Float64, state::NetworkState; 
                            job::Int = 0, overflow::Bool = false)::Vector{TimedEvent}
    new_timed_events = []
    
    next_q = get_next_queue(q, state, overflow = overflow)
    if next_q > 0
        state.in_transit += 1
        push!(new_timed_events, TimedEvent(InTransitEvent(next_q), time + travel_time(state)))
    end

    return new_timed_events
end
