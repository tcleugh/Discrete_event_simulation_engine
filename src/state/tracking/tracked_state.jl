
mutable struct TrackedState <: State
    queues::Vector{Vector{Job}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{Job} #Jobs in transit between queues
    left_system::Vector{Job} #Jobs that have left the system
    params::NetworkParameters #The parameters of the queueing system
end

"""
Constructs an initilized tracked network state from the given parameters
"""
TrackedState(params::NetworkParameters) = TrackedState([Vector{Job}[] for _ in 1:params.L], # Initial queues
                                                            BinaryMinHeap{Job}(),                # Intial transit
                                                            Vector{Job}[],                       # Initial left system
                                                            params)
"""
Constructs an initilized tracked network state from the given parameters and altered λ
"""
TrackedState(params::NetworkParameters, λ::Real) = TrackedState([Vector{Job}[] for _ in 1:params.L], # Initial queues
                                                                    BinaryMinHeap{Job}(),                # Intial transit
                                                                    Vector{Job}[],                       # Initial left system
                                                                    NetworkParameters(params, λ = convert(Float64, λ)))

queued_count(state::TrackedState)::Int = sum([length(state.queues[i]) for i in 1:length(state.queues)])

transit_count(state::TrackedState)::Int = length(state.in_transit)

num_in_queue(q::Int, state::TrackedState)::Int = length(state.queues[q])

""" Prints the current state of the system"""
function show(io::IO, state::TrackedState)
    print(io, "State:\n")
    for (i, queue) in enumerate(state.queues)
        print(io, "Q$i: $(length(queue))\n")
    end
    print(io, "T: $(length(state.in_transit))\n")
end

function new_job(q::Int, time::Float64, state::TrackedState)
    push!(state.queues[q], Job(time)) 
end

function new_transit(time::Float64, transit_time::Float64, state::TrackedState)
    push!(state.in_transit, Job(time, transit_time))
end

function pop_queue(q::Int, time::Float64, state::TrackedState)
    job = popfirst!(state.queues[q])
    job.exit_time = time
    push!(state.left_system, job)
end

function queue_to_transit(q::Int, time::Float64, transit_time::Float64, state::TrackedState)
    job = popfirst!(state.queues[q])
    job.exit_time = transit_time
    push!(state.in_transit, job)
end

function pop_transit(time::Float64, state::TrackedState)
    job = pop!(state.in_transit)
    job.exit_time = time
    push!(state.left_system, job)
end

function transit_to_queue(q::Int, time::Float64, state::TrackedState)
    job = pop!(state.in_transit)
    job.exit_time = time
    push!(state.queues[q], job)
end

function update_transit(time::Float64, transit_time::Float64, state::TrackedState)
    job = pop!(state.in_transit)
    job.exit_time = transit_time
    push!(state.in_transit, job)
end

function failed_arrival(time::Float64, state::TrackedState) 
    push!(state.left_system, Job(time))
end